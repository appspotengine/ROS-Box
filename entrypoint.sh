#!/bin/sh
# Open-Box RouterOS Container Entrypoint Script
set -e

if [ -d "/opt/ROS-Box" ]; then
  OPENBOX_ROOT="/opt/ROS-Box"
else
  OPENBOX_ROOT="/opt/open-box"
fi
DATA="$OPENBOX_ROOT/data"
ETC="$OPENBOX_ROOT/etc"

mkdir -p "$DATA" "$ETC"

# 1. 确保 /dev/net/tun 存在
if [ ! -c /dev/net/tun ]; then
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200 2>/dev/null || true
  chmod 666 /dev/net/tun 2>/dev/null || true
fi

# 2. 修复 RouterOS 7.22+ 容器默认 ip rule 优先级冲突
if command -v ip >/dev/null 2>&1; then
  while ip rule show | grep -Eq '^(1|2|3):\s+from all lookup (local|main|default)'; do
    pref=$(ip rule show | grep -E '^(1|2|3):\s+from all lookup (local|main|default)' | head -n1 | cut -d: -f1)
    ip rule del pref "$pref" 2>/dev/null || break
  done
  while ip rule show | grep -Eq 'pref (32767|2147483646|2147483647) .*lookup (main|default)'; do
    pref=$(ip rule show | grep -E 'pref (32767|2147483646|2147483647) .*lookup (main|default)' | head -n1 | cut -d: -f1)
    ip rule del pref "$pref" 2>/dev/null || break
  done
  ip rule show | grep -Eq 'pref 200 .*lookup local' || ip rule add pref 200 from all lookup local 2>/dev/null || true
  ip rule show | grep -Eq 'pref 32766 .*lookup main' || ip rule add pref 32766 from all lookup main 2>/dev/null || true
  ip rule show | grep -Eq 'pref 32770 .*lookup default' || ip rule add pref 32770 from all lookup default 2>/dev/null || true
fi

# 3. 开启 IPv4 / IPv6 转发并关闭 rp_filter / send_redirects
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > "$i" 2>/dev/null || true; done
for i in /proc/sys/net/ipv4/conf/*/send_redirects; do echo 0 > "$i" 2>/dev/null || true; done

# 3.1 网络吞吐与 TCP Fast Open 低延迟调优 (降低建连延迟，提升千兆高吞吐)
[ -f /proc/sys/net/core/rmem_max ] && echo 16777216 > /proc/sys/net/core/rmem_max 2>/dev/null || true
[ -f /proc/sys/net/core/wmem_max ] && echo 16777216 > /proc/sys/net/core/wmem_max 2>/dev/null || true
echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null || true
echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null || true
echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || true
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null || true
echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || true
ulimit -n 65535 2>/dev/null || ulimit -n 4096 2>/dev/null || true

# 3.2 日志防爆盘自动保护：若日志大于 5MB 则滚动保留最新 1000 行
if [ -f "$DATA/sing-box.log" ]; then
  log_sz=$(wc -c < "$DATA/sing-box.log" 2>/dev/null || echo 0)
  if [ "$log_sz" -gt 5242880 ]; then
    tail -n 1000 "$DATA/sing-box.log" > "$DATA/sing-box.log.tmp" && mv "$DATA/sing-box.log.tmp" "$DATA/sing-box.log"
  fi
fi

# 3.3 局域网 DNS 服务由 node.js 原生 0.0.0.0:53 智能中继守护接管 (支持 Smart DNS 7853 转发与上游自愈兜底)
# 无需 iptables REDIRECT 规则，避免内核未就绪时出现 53 端口黑洞与火绒报错


# 4. 面板端口设置
panel_port=$(cat "$DATA/panel-port" 2>/dev/null | tr -dc '0-9')
if [ -z "$panel_port" ]; then
  panel_port="${PORT:-2026}"
  echo "$panel_port" > "$DATA/panel-port"
fi

# 5. 如果之前保存过配置且自启开启，尝试启动内核
if [ -f "$DATA/autostart" ] && [ -f "$ETC/config.json" ]; then
  echo "[entrypoint] Autostarting sing-box core..."
  /opt/open-box/container/bin/openbox-ctl start || true
fi

# 6. 配置环境变量并启动 Web 控制面板
export PORT="$panel_port"
export HOST="::"
export OPENBOX_ROOT="$OPENBOX_ROOT"
export ZASHBOARD_DB_PATH="$DATA/openbox.sqlite"
export OPENBOX_PLATFORM="container"
export OPENSSL_CONF=/dev/null
export PATH="$OPENBOX_ROOT/container/shim:$PATH"
export OPENBOX_PANEL_HEAP_MB=96
export OPENBOX_PANEL_RSS_LIMIT_MB=180

echo "=========================================================="
echo "  ROS-Box (RouterOS Container Edition) Starting..."
echo "  Web Panel Port: $panel_port"
echo "  Data Path: $DATA"
echo "  Memory Optimization: GOMEMLIMIT=60MiB, GOGC=30, Node Max Heap=96MB"
echo "=========================================================="

# 捕获退出信号
trap '/opt/open-box/container/bin/openbox-ctl stop; exit 0' TERM INT

# 7. 启动 SSH 终端服务 (修复并提供容器直连 SSH 终端管理)
(
  DROPBEAR_BIN=""
  if [ -x /usr/sbin/dropbear ]; then
    DROPBEAR_BIN="/usr/sbin/dropbear"
  elif [ -x /usr/bin/dropbear ]; then
    DROPBEAR_BIN="/usr/bin/dropbear"
  elif command -v dropbear >/dev/null 2>&1; then
    DROPBEAR_BIN="dropbear"
  fi

  if [ -n "$DROPBEAR_BIN" ]; then
    mkdir -p /etc/dropbear
    [ -f /etc/dropbear/dropbear_rsa_host_key ] || dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key 2>/dev/null || true
    [ -f /etc/dropbear/dropbear_ed25519_host_key ] || dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key 2>/dev/null || true
    echo "root:1111" | chpasswd 2>/dev/null || true
    $DROPBEAR_BIN -p 22 -B -R 2>/dev/null || true
    echo "[entrypoint] SSH Terminal daemon ($DROPBEAR_BIN) started on port 22."
  fi
) &

# 启动面板 (优化内存：启用垃圾回收器暴露、限制老生代上限 64MB、启用体积与内联紧缩)
exec node --max-old-space-size=64 --optimize-for-size --expose-gc "$OPENBOX_ROOT/panel/server/index.mjs"

