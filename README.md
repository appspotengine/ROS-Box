# ROS-Box (RouterOS Appliance)

<p align="center">
  <img src="panel/dist/logo-orbit.svg" alt="ROS-Box Logo" width="130" height="130" />
</p>

<p align="center">
  <strong>专为 MikroTik RouterOS 7.x 深度重构的高性能、超轻量旁路由透明代理容器系统</strong><br>
  <em>RouterOS Container Native • Sing-Box 1.14 Core • Sub-60MiB RAM • Self-Healing Networking</em>
</p>

<p align="center">
  <a href="https://github.com/zyeyefyass/ROS-Box/releases/latest"><img src="https://img.shields.io/github/v/release/zyeyefyass/ROS-Box?color=00d2ff&label=Release&logo=github" alt="Latest Release"></a>
  <img src="https://img.shields.io/badge/RouterOS-v7.4~v7.24+-004e82.svg?logo=mikrotik&logoColor=white" alt="RouterOS" />
  <img src="https://img.shields.io/badge/Sing--Box-v1.14-00d2ff.svg" alt="Sing-Box" />
  <img src="https://img.shields.io/badge/Architecture-amd64%20%7C%20arm64-38bdf8.svg" alt="Arch" />
  <img src="https://img.shields.io/badge/Memory-45~55MiB%20Idle-10b981.svg" alt="Memory" />
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue.svg" alt="License" />
</p>

---

## 📸 界面效果预览

<p align="center">
  <img src="docs/images/overview.png" alt="ROS-Box 概览页" width="85%" style="border-radius: 8px; box-shadow: 0 4px 20px rgba(0,45,80,0.3);" />
</p>
<p align="center">
  <em>图 1：ROS-Box 控制台概览页（MikroTik 科技深蓝美学、3D 动力莫比乌斯双环、核心指标实时监控）</em>
</p>

<p align="center">
  <img src="docs/images/settings.png" alt="ROS-Box 设置页" width="85%" style="border-radius: 8px; box-shadow: 0 4px 20px rgba(0,45,80,0.3);" />
</p>
<p align="center">
  <em>图 2：ROS-Box 设置中心（纯净毛玻璃通透层次、无商业引流与广告）</em>
</p>

---

## 🌟 对比原版 Open-Box 的四大核心突破

ROS-Box 在保留上游优秀路由规则体系的同时，彻底剥离了对 OpenWrt / Linux 系统的宿主依赖，针对 **MikroTik RouterOS 容器沙盒环境** 进行了深度内核级架构重构：

### 1. ⚡ 60MiB 极省内存架构 (`GOMEMLIMIT=60MiB`)
- **原版痛点**：原版 Open-Box 基于完整 OpenWrt 虚拟机或 Debian 宿主环境，包含全套守护进程与 Node 运行环境，开销通常在 180MB~350MB 以上，无法在 RB5009、hAP ax2/ax3 等内存受限的路由器上稳定常驻。
- **ROS-Box 突破**：
  - 深度裁剪死代码与开发期依赖，剔除臃肿冗余；
  - 强制注入 Go 运行时内存软上限 `GOMEMLIMIT=60MiB`，开启激进垃圾回收；
  - 面板与 Sing-Box 双进程**空闲常驻内存仅 45 ~ 55 MiB**，千兆满载峰值不超 80 MiB，彻底终结 OOM 爆内存崩溃。

### 2. 🛡️ RouterOS 7.22+ 策略路由缺陷自愈 (`Self-Healing ip rule`)
- **原版痛点**：MikroTik RouterOS 从 v7.22 版本开始，在容器命名空间内默认强行下发优先级最高的系统策略路由规则（`1: local`, `2: main`, `3: default`）。这会导致 Sing-Box TUN 模式自动下发的策略路由被彻底阻断，出现“内核显示正常运行，但局域网设备无论如何无法走代理”的严重系统缺陷。
- **ROS-Box 突破**：
  - 内置专为 RouterOS 研发的**规则动态重排与自愈引擎**（`openbox-ctl` & `entrypoint.sh`）；
  - 容器启动与运行期间自动抹除 RouterOS 的 1/2/3 号冲突规则，并平滑下移至标准优先级，实现 **0 脚本维护、开机即用、100% 顺畅接管流量**。

### 3. 🚀 Smart DNS 零泄露并发竞速 (Smart DNS 0ms Multi-Upstream Racing)
- **原版痛点**：原版严重依赖 OpenWrt 宿主机的 `dnsmasq` 配置文件注入和服务重启，在纯容器环境中由于缺少 `uci` 与 `dnsmasq`，极易导致 DNS 模块报错崩溃、发生 DNS 污染或境外 DNS 解析泄露。
- **ROS-Box 突破**：
  - 容器内嵌 7853 独立 Smart DNS 防劫持引擎，彻底脱离宿主 `dnsmasq`；
  - **国内 DNS 三路并发竞速**：AliDNS + DNSPod + 运营商本地 DNS 三路并行竞速，取最快返回结果（降至极限 1~3ms）；
  - **海外流量 0 泄露机制**：国外域名强制通过已加密的出站代理隧道进行远程解析（Split-DNS 隔离），杜绝任何 DNS 污染与隐私泄露。

### 4. 🌐 TCP Fast Open (TFO) 与千兆高吞吐调优
- **原版痛点**：原版未对容器沙盒内的高并发 socket 限制与 TCP 拥塞控制做特化调优。
- **ROS-Box 突破**：
  - 启动阶段全局激活 `TCP Fast Open (TFO)`，三次握手首包直接携带应用层请求数据，大幅压缩网页首次加载的 RTT 延迟；
  - 调高 socket 缓冲区与内核参数（`ulimit -n 65535`、`tcp_window_scaling=1`、BBR 拥塞控制适配）；
  - 内置日志滚动防爆盘机制（>5MB 自动裁切），保护路由器闪存寿命。

---

## 📊 原版 Open-Box vs ROS-Box 全方位对比

| 对比维度 | 原版 Open-Box (Upstream) | ROS-Box (本项目专属) |
| :--- | :--- | :--- |
| **适配平台** | 仅限 OpenWrt 系统 / Debian 系统 | **MikroTik RouterOS 7.x 专属** + 通用 Docker |
| **系统依赖** | 强依赖 `uci`、`ubus`、`procd`、宿主 `dnsmasq` | **零系统依赖**，独立容器沙盒生命周期管理 |
| **ROS 7.22+ 兼容** | ❌ 策略路由冲突，TUN 流量被拦截失效 | **✅ 内置 `ip rule` 自动修复与自愈引擎** |
| **空闲运行内存** | 180 ~ 350+ MiB (易导致路由器 OOM) | **✅ 仅 45 ~ 55 MiB** (`GOMEMLIMIT=60MiB`) |
| **容器离线打包** | 镜像体积大，无开箱即用 RouterOS `.tar` | **✅ 单层高压 Squash 离线包 (220MB .tar / 87MB .tar.gz)** |
| **硬件架构** | 视 OpenWrt 编译固件而定 | **✅ 官方双架构：`linux/amd64` (x86/CHR) + `linux/arm64` (RB5009等)** |
| **DNS 架构** | 注入宿主 dnsmasq，易受污染/泄露 | **✅ 内置 Smart DNS 多路竞速 (1~3ms) + Split-DNS 零泄露** |
| **视觉与体验** | 原生浅色，包含商业推广卡片与外链 | **✅ MikroTik 科技深蓝美学 + 3D 动力双环 Logo + 纯净去推广** |
| **更新自动化** | 手动下载更新 | **✅ GitHub Actions 每日 11:00 / 23:00 自动巡检上游并自动发版** |

---

## 🚀 部署指南

### 一、RouterOS 7.x 部署（推荐）

#### 准备工作：开启容器功能、磁盘挂载与虚拟网卡配置

1. **开启容器功能**：
   在 WinBox 打开 **Terminal**，执行：
   ```routeros
   /system/device-mode/update container=yes
   ```
   按提示按下设备物理 Reset 键或在 3-5 分钟内执行 `/system/reboot`。
2. **挂载外置存储**：
   外置 USB/SSD 请进入 **System → Disks** 格式化为 **ext4**（假设盘符为 `disk1`）。
3. **创建虚拟网卡 (VETH) 并加入局域网网桥 (Bridge)**：
   *这一步是容器与局域网设备互通的关键，请在 Terminal 中执行以下两行命令：*
   ```routeros
   # 1. 创建 VETH 虚拟网卡 (指定容器 IP，例如 192.168.88.2，网关指向路由器 192.168.88.1)
   /interface/veth add name=veth-rosbox address=192.168.88.2/24 gateway=192.168.88.1

   # 2. 将虚拟网卡加入局域网 Bridge 网桥
   /interface/bridge/port add bridge=bridge interface=veth-rosbox comment="ROS-Box Container VETH"
   ```
   *(亦可在 WinBox 中操作：**Interfaces → VETH** 点 `+` 新建；然后在 **Bridge → Ports** 点 `+` 将 `veth-rosbox` 加入 `bridge`)*

---

#### 方式 1：RouterOS 终端一键命令部署（最快、最省心）
复制以下单行命令，直接粘贴至 WinBox Terminal 回车即可自动完成挂载点与容器的极速拉取与创建：

```routeros
/tool fetch url="https://raw.githubusercontent.com/zyeyefyass/ROS-Box/main/scripts/ros-install-tar-gateway.rsc" dst-path="disk1/ros-install.rsc"; /import file=disk1/ros-install.rsc
```

> **提示**：脚本默认容器 IP 为 `192.168.88.2/24`，网关为 `192.168.88.1`。如需修改，可在导入前编辑脚本内的变量。

---

#### 方式 2：WinBox 图形化拖拽 `.tar` 离线部署（适合无外网环境）
1. 从 [Releases 页面](https://github.com/zyeyefyass/ROS-Box/releases/latest) 下载离线安装包：
   - x86 / CHR 软路由：下载 **`ROS-Box-amd64.tar`**
   - RB5009 / CCR / ax2 / ax3 等 ARM 路由：下载 **`ROS-Box-arm64.tar`**
2. 打开 WinBox **Files**，直接把下载的 `.tar` 文件拖入 `disk1/` 目录；
3. **确认虚拟网卡已加入 Bridge**（若准备工作第 3 步已执行可跳过）：
   - WinBox **Interfaces → VETH**：确保 `veth-rosbox` 存在；
   - WinBox **Bridge → Ports**：确保 `veth-rosbox` 已作为 Port 加入主 LAN `bridge`；
4. 进入 **Container → Mounts**，创建两处持久化挂载：
   - 挂载点 1：Name=`rosbox-data`, Src=`disk1/rosbox/data`, Dst=`/opt/open-box/data`
   - 挂载点 2：Name=`rosbox-etc`, Src=`disk1/rosbox/etc`, Dst=`/opt/open-box/etc`
5. 进入 **Container → Containers**，点击 **`+`** 号：
   - **File**：选择 `disk1/ROS-Box-amd64.tar`（或 arm64 包）
   - **Interface**：选择下拉菜单中的 **`veth-rosbox`**
   - **Root Dir**：`disk1/rosbox/root`
   - **Mounts**：勾选 `rosbox-data` 和 `rosbox-etc`
   - **Logging** 与 **Start on Boot**：勾选 `yes`
6. 点击 **Apply/OK**，等待状态由 `extracting...` 变为 `stopped`（解压完成），点击 **Start** 启动即可！

---

### 二、标准 Docker 环境部署

如果您希望将 ROS-Box 运行在 Linux 主机、软路由、PVE 或 NAS Docker 中，支持以下两种部署方式：

#### 方式 1：Docker CLI 一键命令部署
```bash
docker run -d \
  --name ros-box \
  --restart unless-stopped \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -p 2026:2026 \
  -p 7853:7853/udp \
  -p 7853:7853/tcp \
  -p 7890:7890 \
  --sysctl net.ipv4.ip_forward=1 \
  -v /opt/rosbox/data:/opt/open-box/data \
  -v /opt/rosbox/etc:/opt/open-box/etc \
  ghcr.io/zyeyefyass/ros-box:latest
```

#### 方式 2：Docker Compose 一键部署
在项目根目录或新建 `docker-compose.yml`：
```yaml
services:
  ros-box:
    image: ghcr.io/zyeyefyass/ros-box:latest
    container_name: ros-box
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - "2026:2026"
      - "7853:7853/udp"
      - "7853:7853/tcp"
      - "7890:7890"
    sysctls:
      - net.ipv4.ip_forward=1
    volumes:
      - ./data:/opt/open-box/data
      - ./etc:/opt/open-box/etc
    environment:
      - PORT=2026
      - OPENBOX_PLATFORM=container
```
执行启动命令：
```bash
docker compose up -d
```

---

## 💻 访问与使用

1. 打开浏览器访问：`http://<容器IP>:2026`（例如 `http://192.168.88.2:2026`）；
2. 首次进入设置管理员登录密码；
3. 进入 **订阅管理** 添加节点订阅链接；
4. 进入 **设置中心** 选择分流策略，点击右上角 **部署 / 启动内核**。

---

## 🔄 自动化上游同步与发布机制

仓库内置 [`.github/workflows/upstream-sync.yml`](.github/workflows/upstream-sync.yml) CI/CD 自动化流水线：
- **定时巡检**：每天 **11:00**（北京时间）与 **23:00**（北京时间）自动检测上游 [liandu2024/Open-Box](https://github.com/liandu2024/Open-Box) 的最新 Release；
- **全自动发布**：当下游检测到新版本发布时，自动触发多架构（`linux/amd64` 与 `linux/arm64`）镜像编译构建，生成与上游版本号一致的 GitHub Releases 离线包与校验码，实现永久无人值守自动同步。

---

## 📜 开源协议与致谢

- 本项目基于 **GPL-3.0** 协议开源。
- 特别鸣谢：
  - [liandu2024/Open-Box](https://github.com/liandu2024/Open-Box)
  - [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
  - [MikroTik RouterOS](https://mikrotik.com/)
