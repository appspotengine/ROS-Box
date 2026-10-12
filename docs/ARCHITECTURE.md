# Open-Box RouterOS 容器化架构与二次开发技术说明

本项目对 [liandu2024/Open-Box](https://github.com/liandu2024/Open-Box) 进行了深入解构与架构改造，使其能够作为 OCI/Docker 容器无缝运行在 MikroTik RouterOS 7.x 的 Container 引擎中，亦可在标准 Docker/Podman 等容器环境中独立运行。

---

## 1. 原项目架构分析与瓶颈

原版 Open-Box 针对 OpenWrt 深度定制，后续演进增加了 Debian/Ubuntu (systemd) 的支持，其底层严重依赖主机操作系统特性：

1. **服务生命周期管理依赖**：
   - OpenWrt 上依赖 `procd` (`/etc/init.d/openbox`, `/etc/init.d/openbox-panel`)；
   - Debian 上依赖 `systemd` (`systemctl` 单元及 `debian/bin/openbox-ctl`)；
   - 在 RouterOS 容器中，既没有 `procd` 也没有 `systemd`，PID 1 仅为常规 Entrypoint 脚本。
2. **防火墙与网络接管依赖**：
   - 依赖 OpenWrt 的 `uci`、`fw4`（动态生成 LAN 放行、TUN 转发规则）；
   - 依赖宿主机 `dnsmasq` 配置文件注入和重启；
   - 容器内不具备宿主机的 `uci` 与 `dnsmasq` 工具。
3. **日志获取依赖**：
   - 原项目诊断模块与崩溃检测依赖 OpenWrt 的 `logread` 或 Debian 的 `journalctl`。
4. **RouterOS 容器环境特殊限制**：
   - **RouterOS 7.22+ `ip rule` 优先级冲突**：ROS 7.22 引入了默认的优先规则（`1: local`, `2: main`, `3: default`），这导致 sing-box TUN 自动创建的策略路由（规则优先级高于 3）无法被命中，出现“内核显示运行，但流量死活进不来/不走代理”的严重故障。
   - **/dev/net/tun 设备节点**：部分容器环境默认不自动创建 `/dev/net/tun` 字符设备。
   - **转发开关**：容器 namespace 内部需显式配置 `net.ipv4.ip_forward=1`。

---

## 2. 二次开发核心改造实现

针对上述痛点，本项目在代码与工程层面进行了如下深度改造：

### 2.1 引入全新 `container` 平台标识
在服务端多处关键模块增加并规范化了 `container` 平台逻辑：

- **`panel/server/system/platform.mjs`**：
  - 注册 `PLATFORMS = ['openwrt', 'systemd', 'container']`。
  - 增加对 `/.dockerenv`、`/run/.containerenv`、`OPENBOX_PLATFORM=container` 的自动嗅探。
  - 将原本硬编码的 `isOpenWrt(p) => p !== 'systemd'` 改为精确判断 `isOpenWrt(p) => p === 'openwrt'`。
- **`panel/server/system/paths.mjs`**：
  - 平台为 `container` 时，将核心与面板的管理脚本重定向到容器内置的控制脚本：
    ```javascript
    initd: platform === 'systemd'
      ? { core: `${root}/debian/bin/openbox-ctl`, panel: `${root}/debian/bin/openbox-panel-ctl` }
      : platform === 'container'
      ? { core: `${root}/container/bin/openbox-ctl`, panel: `${root}/container/bin/openbox-panel-ctl` }
      : { core: '/etc/init.d/openbox', panel: '/etc/init.d/openbox-panel' }
    ```
- **`panel/server/system/deploy.mjs`**：
  - 屏蔽所有针对 OpenWrt `uci` 防火墙（`applyPanelLanRule`、`applyTunForwardRule` 等）的调用。
  - 在部署失败回滚（`rollbackToDirect`）时跳过 `restoreDnsTakeover` 和 `removeProxyRules`，避免因缺少 `uci` 而报错导致回滚失败。
- **`panel/server/store/openbox-store.mjs`**：
  - 非 OpenWrt 平台（包括容器环境）默认将 DNS 模式置为 `hijack`（内核防火墙劫持），而不是宿主机的 `dnsmasq` 模式。

---

### 2.2 容器进程管理与 RouterOS 7.22+ 兼容补丁 (`container/bin/openbox-ctl`)
我们编写了容器专用的服务管理脚本 `openbox-ctl`，对接面板的 `start`, `stop`, `restart`, `status`, `enable`, `disable`, `enabled` 指令：

1. **自动清理 RouterOS 7.22+ 冲突路由规则**：
   ```bash
   while ip rule show | grep -Eq '^(1|2|3):\s+from all lookup (local|main|default)'; do
     pref=$(ip rule show | grep -E '^(1|2|3):\s+from all lookup (local|main|default)' | head -n1 | cut -d: -f1)
     ip rule del pref "$pref" 2>/dev/null || break
   done
   ip rule show | grep -Eq 'pref 200 .*lookup local' || ip rule add pref 200 from all lookup local 2>/dev/null || true
   ip rule show | grep -Eq 'pref 2147483646 .*lookup main' || ip rule add pref 2147483646 from all lookup main 2>/dev/null || true
   ip rule show | grep -Eq 'pref 2147483647 .*lookup default' || ip rule add pref 2147483647 from all lookup default 2>/dev/null || true
   ```
2. **字符设备与内核参数动态就绪**：
   - 自动检测并补齐 `/dev/net/tun` (`mknod /dev/net/tun c 10 200`)。
   - 动态启用 `sysctl -w net.ipv4.ip_forward=1`。
3. **NAT MASQUERADE 动态放行**：
   - 当局域网客户端使用容器作为网关时，直连出站流量经容器 `eth0` 返回 RouterOS 前自动执行 MASQUERADE，防止因非对称路由引发连接中断。
4. **精确 PID 与生命周期监控**：
   - 记录 `sing-box.pid`，后台执行并在启动后校验 1 秒存活性；停止时执行优雅 TERM 与超时 KILL。

---

### 2.3 日志替身适配 (`container/shim/logread`)
- 面板的崩溃检测（`readLastKernelFatal`）通过调用系统命令 `logread` 来判断内核是否报错。
- 我们在 `container/shim/logread` 提供了一个纯 shell 实现的 `logread` 兼容层，实时读取 `/opt/open-box/data/sing-box.log`，支持 `-e` 正则过滤与 `-l` 行数限制，完美兼容面板的所有日志检查逻辑。

---

### 2.4 轻量多架构镜像构建 (`Dockerfile`)
- 基础镜像基于 `node:22-alpine`，总镜像大小仅约 120MB（远小于原版 200MB+ 打包）。
- Node 22 原生提供 `node:sqlite`（`DatabaseSync`），无缝满足 Open-Box 数据存储需求，免除跨平台编译 C 扩展的困扰。
- 支持通过 Docker Buildx 一键构建 `linux/amd64` (CHR/x86工控机) 与 `linux/arm64` (MikroTik RB5009, CCR2004, CCR2116, hAP ax 系列)。
