# ROS-Box (RouterOS Appliance)

<p align="center">
  <img src="https://raw.githubusercontent.com/zyeyefyass/ROS-Box/main/panel/dist/logo-cube-v3.svg" alt="ROS-Box Logo" width="130" height="130" />
</p>

<p align="center">
  <strong>专为 MikroTik RouterOS 7.x、NAS Docker（飞牛 fnOS / 群晖 / Unraid）及 Linux 物理机/虚拟机深度打造的高性能、超轻量旁路由透明代理系统</strong><br>
  <em>RouterOS • NAS Docker • Linux Bare-Metal & VM • Sing-Box 1.14 Core • Sub-60MiB RAM • Self-Healing Networking</em>
</p>

<p align="center">
  <a href="https://github.com/zyeyefyass/ROS-Box/releases/latest"><img src="https://img.shields.io/github/v/release/zyeyefyass/ROS-Box?color=00d2ff&label=Release&logo=github" alt="Latest Release"></a>
  <a href="https://hub.docker.com/r/fyasshole/ros-box"><img src="https://img.shields.io/badge/Docker_Hub-fyasshole%2Fros--box-2496ED?logo=docker&logoColor=white" alt="Docker Hub"></a>
  <img src="https://img.shields.io/badge/RouterOS-v7.4~v7.24+-004e82.svg?logo=mikrotik&logoColor=white" alt="RouterOS" />
  <img src="https://img.shields.io/badge/NAS_Docker-fnOS%20%7C%20Synology%20%7C%20Unraid-0ea5e9.svg?logo=docker&logoColor=white" alt="NAS Docker" />
  <img src="https://img.shields.io/badge/Linux_Host-Debian%20%7C%20Ubuntu%20%7C%20Armbian%20%7C%20PVE-f59e0b.svg?logo=linux&logoColor=white" alt="Linux Host" />
  <img src="https://img.shields.io/badge/Sing--Box-v1.14-00d2ff.svg" alt="Sing-Box" />
  <img src="https://img.shields.io/badge/Architecture-amd64%20%7C%20arm64-38bdf8.svg" alt="Arch" />
  <img src="https://img.shields.io/badge/Memory-45~55MiB%20Idle-10b981.svg" alt="Memory" />
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue.svg" alt="License" />
</p>

---

## 📸 界面效果预览

<p align="center">
  <img src="https://raw.githubusercontent.com/zyeyefyass/ROS-Box/main/docs/images/overview.png" alt="ROS-Box 概览页" width="85%" style="border-radius: 8px; box-shadow: 0 4px 20px rgba(0,45,80,0.3);" />
</p>
<p align="center">
  <em>图 1：ROS-Box 控制台概览页（MikroTik 科技深蓝美学、3D 动力莫比乌斯双环、核心指标实时监控）</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/zyeyefyass/ROS-Box/main/docs/images/settings.png" alt="ROS-Box 设置页" width="85%" style="border-radius: 8px; box-shadow: 0 4px 20px rgba(0,45,80,0.3);" />
</p>
<p align="center">
  <em>图 2：ROS-Box 设置中心（纯净毛玻璃通透层次、无商业引流与广告）</em>
</p>

---

## 🌟 对比原版 Open-Box 的四大核心突破

ROS-Box 在保留上游优秀路由规则体系的同时，彻底剥离了对 OpenWrt 宿主系统的强耦合依赖，针对 **MikroTik RouterOS 7.x 容器沙盒**、**飞牛 fnOS / 群晖 / Unraid 等 NAS Docker 环境** 以及 **Linux 物理机 / 虚拟机（Debian / Ubuntu / Armbian / PVE）** 进行了深度内核级架构重构：

### 1. ⚡ 60MiB 极省内存架构 (`GOMEMLIMIT=60MiB`)
- **原版痛点**：原版 Open-Box 基于完整 OpenWrt 虚拟机或臃肿宿主环境，包含全套守护进程与 Node 运行环境，开销通常在 180MB~350MB 以上，无法在 RB5009、hAP ax2/ax3 或低功耗 ARM 盒子上稳定常驻。
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
- **原版痛点**：原版严重依赖 OpenWrt 宿主机的 `dnsmasq` 配置文件注入和服务重启，在纯容器或精简 Linux 物理机环境中由于缺少 `uci` 与 `dnsmasq`，极易导致 DNS 模块报错崩溃、发生 DNS 污染或境外 DNS 解析泄露。
- **ROS-Box 突破**：
  - 内嵌 7853 独立 Smart DNS 防劫持引擎，彻底脱离宿主 `dnsmasq`；
  - **国内 DNS 三路并发竞速**：AliDNS + DNSPod + 运营商本地 DNS 三路并行竞速，取最快返回结果（降至极限 1~3ms）；
  - **海外流量 0 泄露机制**：国外域名强制通过已加密的出站代理隧道进行远程解析（Split-DNS 隔离），杜绝任何 DNS 污染与隐私泄露。

### 4. 🌐 TCP Fast Open (TFO) 与千兆高吞吐调优
- **原版痛点**：原版未对高并发 socket 限制与 TCP 拥塞控制做特化调优。
- **ROS-Box 突破**：
  - 启动阶段全局激活 `TCP Fast Open (TFO)`，三次握手首包直接携带应用层请求数据，大幅压缩网页首次加载的 RTT 延迟；
  - 调高 socket 缓冲区与内核参数（`ulimit -n 65535`、`tcp_window_scaling=1`、BBR 拥塞控制适配）；
  - 内置日志滚动防爆盘机制（>5MB 自动裁切），保护设备闪存寿命。

---

## 📊 原版 Open-Box vs ROS-Box 全方位对比

| 对比维度 | 原版 Open-Box (Upstream) | ROS-Box (本项目专属) |
| :--- | :--- | :--- |
| **适配平台** | 仅限特定 OpenWrt / Debian 环境 | **MikroTik RouterOS 7.x + NAS Docker (飞牛 fnOS/群晖/Unraid) + Linux 物理机/虚拟机 (Debian/Ubuntu/Armbian/PVE)** |
| **系统依赖** | 强依赖 `uci`、`ubus`、`procd`、宿主 `dnsmasq` | **零系统依赖**，独立沙盒与自包含生命周期管理 |
| **ROS 7.22+ 兼容** | ❌ 策略路由冲突，TUN 流量被拦截失效 | **✅ 内置 `ip rule` 自动修复与自愈引擎** |
| **空闲运行内存** | 180 ~ 350+ MiB (易导致路由器 OOM) | **✅ 仅 45 ~ 55 MiB** (`GOMEMLIMIT=60MiB`) |
| **容器离线打包** | 镜像体积大，无开箱即用 RouterOS `.tar` | **✅ 内置 Gzip 高压 `.tar` 离线包 (~111 MB，解压后 223 MiB)** |
| **硬件架构** | 视 OpenWrt 编译固件而定 | **✅ 官方双架构：`linux/amd64` (x86物理机/工控机/NAS/CHR) + `linux/arm64` (RB5009/ARM盒子等)** |
| **DNS 架构** | 注入宿主 dnsmasq，易受污染/泄露 | **✅ 内置 Smart DNS 多路竞速 (1~3ms) + Split-DNS 零泄露** |
| **视觉与体验** | 原生浅色，包含商业推广卡片与外链 | **✅ MikroTik 科技深蓝美学 + 3D 动力双环 Logo + 纯净去推广** |
| **更新自动化** | 手动下载更新 | **✅ GitHub Actions 每日 11:00 / 23:00 自动巡检上游并自动发版** |

---

## 🚀 部署指南

### 一、RouterOS 7.x 部署（推荐）

#### 准备工作：开启容器功能、存储目录与虚拟网卡配置

1. **开启容器功能**：
   在 WinBox 打开 **Terminal**，执行：
   ```routeros
   /system/device-mode/update container=yes
   ```
   按提示按下设备物理 Reset 键或在 3-5 分钟内执行 `/system/reboot`。
2. **准备存储目录（`/disk1`）**：
   - **大多数场景（x86 软路由 / PVE / ESXi / CHR / RB5009 等内置空间充足设备）**：**无需外接硬盘**，直接在 RouterOS 内置存储中创建或使用 `/disk1` 目录即可（执行下方挂载点命令时系统也会在根目录自动生成 `/disk1/rosbox/...`）。
   - **小闪存硬件（可选，如 128MB 闪存的 hAP ax2/ax3）**：如内置空间不足，可插入外置 USB/SSD 并在 **System → Disks** 格式化为 **ext4**（默认挂载名同样为 `disk1`）。
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

### 🇨🇳 针对国内无科学上网环境的三大极速部署方案 (100% 成功率)

在初次配置旁路由时，RouterOS 本身往往无法直接访问 GitHub。为此我们深度适配了国内加速镜像与纯离线部署通道，无需任何科学上网环境即可秒级完成安装：

#### 方案一：国内加速镜像直连（纯命令行一键部署，推荐 ⭐⭐⭐⭐⭐）
直接复制命令粘贴进 WinBox **Terminal** 回车，RouterOS 将通过国内高速镜像节点（`ghproxy.net`）自动拉取镜像并部署：

1. **自动拉取镜像包至路由器 `/disk1` 目录（按设备架构二选一）**：
   - **x86 PC 软路由 / CHR 虚拟机 / 工控机 (`amd64`)**：
     ```routeros
     /tool fetch url="https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/download/v0.1.317/ROS-Box-amd64.tar" dst-path="disk1/ROS-Box-amd64.tar" mode=https
     ```
   - **MikroTik RB5009 / CCR / ax2 / ax3 (`arm64`)**：
     ```routeros
     /tool fetch url="https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/download/v0.1.317/ROS-Box-arm64.tar" dst-path="disk1/ROS-Box-arm64.tar" mode=https
     ```

2. **一键创建网卡、挂载点并导入容器**：
   在 Terminal 中粘贴执行以下纯本地配置（以 x86 为例，ARM64 请将 `file=` 参数改为 `disk1/ROS-Box-arm64.tar`）：
   ```routeros
   # 1. 确保虚拟网卡与网桥就绪
   /interface/veth add name=veth-rosbox address=192.168.88.2/24 gateway=192.168.88.1
   /interface/bridge/port add bridge=bridge interface=veth-rosbox comment="ROS-Box Container VETH"

    # 2. 建立持久化数据挂载卷
   /container/mounts add name=rosbox-data src="disk1/rosbox/data" dst="/opt/ROS-Box/data"
   /container/mounts add name=rosbox-etc src="disk1/rosbox/etc" dst="/opt/ROS-Box/etc"

   # 3. 导入本地镜像创建容器
   /container add file=disk1/ROS-Box-amd64.tar interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
   ```

3. **启动容器**：
   观察 WinBox Container 列表中状态从 `extracting...` 变为 `stopped` 后执行：
   ```routeros
   /container/start [find comment="ROS-Box"]
   ```

---

#### 方案二：PC 电脑拖拽 WinBox Files + 纯离线命令（最稳固，零网络依赖）
电脑端下载安装包通常比路由器更灵活：

1. **电脑直接下载离线镜像包（国内直连加速链接）**：
   - 💻 [ROS-Box-amd64.tar 国内加速下载 (x86/CHR)](https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/download/v0.1.317/ROS-Box-amd64.tar)
   - 📱 [ROS-Box-arm64.tar 国内加速下载 (RB5009/CCR/ax等)](https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/download/v0.1.317/ROS-Box-arm64.tar)
2. **WinBox 极速拖拽**：
   打开 WinBox 左侧菜单 **Files**，直接把下载好的 `.tar` 文件拖入 `disk1/` 目录（内网千兆仅需 5~10 秒）。
3. **在 Terminal 执行方案一的第 2、3 步配置命令** 即可完成秒级导入！

---

#### 方案三：局域网内部飞速中转拉取（零公网流量，千兆内网直传）
如果路由器当前无法连接外网，可利用同局域网的电脑快速分发：
1. 在存放 `ROS-Box-amd64.tar` 的电脑文件夹中打开终端（PowerShell / CMD），启动临时微型 HTTP 服务：
   ```powershell
   python -m http.server 8000
   ```
2. 在 RouterOS Terminal 中直接向局域网电脑拉取（假设电脑 IP 为 `192.168.88.10`）：
   ```routeros
   /tool fetch url="http://192.168.88.10:8000/ROS-Box-amd64.tar" dst-path="disk1/ROS-Box-amd64.tar"
   ```
3. 拉取完成后，直接执行容器导入命令即可。

---

### 🌐 海外/已有代理环境一键直连命令

如果您的路由器环境已具备国际互联网访问能力，可直接运行一键式远程脚本：
```routeros
/tool fetch url="https://raw.githubusercontent.com/zyeyefyass/ROS-Box/main/scripts/ros-install-tar-gateway.rsc" dst-path="disk1/ros-install.rsc"; /import file=disk1/ros-install.rsc
```

---

### 二、NAS Docker（飞牛 fnOS / 群晖 / Unraid / CasaOS / 1Panel）部署

本项目已同步发布至 **Docker Hub ([`fyasshole/ros-box`](https://hub.docker.com/r/fyasshole/ros-box))** 与 **GitHub Container Registry (`ghcr.io/zyeyefyass/ros-box`)**，原生支持 `linux/amd64` 与 `linux/arm64` 双架构。

> 💡 **为什么 NAS 旁路由推荐使用独立 Macvlan 网络？**
> 使用 **Macvlan** 可为 `ROS-Box` 容器分配一个**局域网内完全独立的 IP 与 MAC 地址**（例如飞牛 NAS 是 `192.168.88.10`，ROS-Box 独立 IP 是 `192.168.88.2`），不会占用飞牛宿主机的 53 (DNS) 端口，也不影响飞牛自身的网络与路由表，体验与独立硬件旁路由完全一致！

---

#### 方式 1：飞牛 fnOS 独立 IP（Macvlan）完整保姆级部署教程（强烈推荐 ⭐⭐⭐⭐⭐）

##### 第一步：在飞牛「镜像仓库」搜索下载镜像
1. 打开飞牛 fnOS 桌面 **Docker → 镜像仓库**；
2. 在顶部搜索框直接输入 **`ros-box`**（或 **`fyasshole/ros-box`**），点击下载官方镜像（标签选择 `latest`）。

##### 第二步：创建飞牛 Macvlan 独立局域网（仅首次需执行一次）
通过 SSH 连接飞牛 fnOS，执行以下 3 条命令创建 Macvlan 网络（请将 `192.168.88.0/24` 和网关 `192.168.88.1` 替换为您实际的局域网网段）：
```bash
# 1. 查看飞牛主网卡名称（例如 enp3s0、eth0；若开启了虚拟机网桥通常为 enp3s0-ovs）
ip route | grep default

# 2. 开启物理网卡混杂模式（将 enp3s0 替换为上一步查到的实际网卡名）
sudo ip link set enp3s0 promisc on

# 3. 创建名为 macvlan-net 的 Docker 独立网络
sudo docker network create -d macvlan \
  --subnet=192.168.88.0/24 \
  --gateway=192.168.88.1 \
  -o parent=enp3s0 \
  macvlan-net
```

##### 第三步：启动容器并绑定固定旁路由 IP（提供 Compose 与纯图形界面两种选法）

- **选法 A：通过飞牛「Compose → 新增项目」固定独立 IP 启动（最推荐，重启 IP 永不变化）**
  打开 **飞牛 Docker → Compose → 新增项目**，项目名称填 `ros-box`，选择存放路径后勾选 **「创建 docker-compose.yml」**，粘贴以下内容（将 `192.168.88.2` 改为您想分配给 ROS-Box 的空闲局域网 IP）：
  ```yaml
  services:
    ros-box:
      image: fyasshole/ros-box:latest
      container_name: ros-box
      restart: always
      privileged: true
      cap_add:
        - NET_ADMIN
        - SYS_ADMIN
      devices:
        - /dev/net/tun:/dev/net/tun
      networks:
        macvlan-net:
          ipv4_address: 192.168.88.2  # 为 ROS-Box 分配的局域网独立旁路由 IP
      dns:
        - 223.5.5.5
        - 119.29.29.29
      volumes:
        - ./data:/opt/ROS-Box/data
        - ./etc:/opt/ROS-Box/etc
      environment:
        - TZ=Asia/Shanghai
        - PORT=2026
        - OPENBOX_PLATFORM=container

  networks:
    macvlan-net:
      external: true
  ```
  点击创建并启动后，直接在浏览器访问 **`http://192.168.88.2:2026`** 即可进入 ROS-Box 控制台！局域网需要科学上网的设备只需将 **网关** 和 **DNS** 指向 `192.168.88.2` 即可。

- **选法 B：通过飞牛「本地镜像 → 运行」纯图形化向导创建**
  1. 进入 **飞牛 Docker → 本地镜像**，找到下载好的 `fyasshole/ros-box:latest` 点击右侧 **「运行」**；
  2. **基础设置**：勾选 **「开机自启」**；展开高级设置，勾选 **「使用最高权限执行容器 (Privileged)」**；
  3. **存储位置（文件夹映射）**：
     - 点击「添加路径」：选择飞牛本地新建的 `data` 文件夹 → 装载路径填 **`/opt/ROS-Box/data`**（权限：读写）
     - 点击「添加路径」：选择飞牛本地新建的 `etc` 文件夹 → 装载路径填 **`/opt/ROS-Box/etc`**（权限：读写）
  4. **网络**：下拉选择刚刚创建的 **`macvlan-net`**（若不想配 Macvlan，也可在此直接选 **`host`** 模式，此时访问地址为 `http://<飞牛IP>:2026`）；
  5. 点击完成创建即可一键启动！

---

#### 方式 2：标准 Docker Compose 部署（Bridge / Host 模式通用）
如果您不需要 Macvlan 独立 IP，可直接使用标准端口映射模式新建 `docker-compose.yml`：
```yaml
services:
  ros-box:
    # Docker Hub 官方镜像（也可替换为 ghcr.io/zyeyefyass/ros-box:latest）
    image: fyasshole/ros-box:latest
    container_name: ros-box
    restart: unless-stopped
    privileged: true
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
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
      - ./data:/opt/ROS-Box/data
      - ./etc:/opt/ROS-Box/etc
    environment:
      - TZ=Asia/Shanghai
      - PORT=2026
      - OPENBOX_PLATFORM=container
```

#### 方式 3：Docker CLI 一键命令部署（Macvlan 独立 IP 或端口映射）
- **Macvlan 独立旁路由 IP 一键启动命令**：
  ```bash
  docker run -d \
    --name ros-box \
    --restart always \
    --network macvlan-net \
    --ip 192.168.88.2 \
    --privileged \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    --dns 223.5.5.5 \
    -v /opt/rosbox/data:/opt/ROS-Box/data \
    -v /opt/rosbox/etc:/opt/ROS-Box/etc \
    -e TZ=Asia/Shanghai \
    fyasshole/ros-box:latest
  ```
- **标准端口映射一键启动命令**：
  ```bash
  docker run -d \
    --name ros-box \
    --restart unless-stopped \
    --privileged \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    -p 2026:2026 \
    -p 7853:7853/udp \
    -p 7853:7853/tcp \
    -p 7890:7890 \
    --sysctl net.ipv4.ip_forward=1 \
    -v /opt/rosbox/data:/opt/ROS-Box/data \
    -v /opt/rosbox/etc:/opt/ROS-Box/etc \
    -e TZ=Asia/Shanghai \
    fyasshole/ros-box:latest
  ```

---

### 三、Linux 物理机 / 虚拟机（Debian / Ubuntu / Armbian / PVE）旁路由部署

如果您使用的是 **x86 小主机（N100 / J4125 等）**、**ARM 盒子（R2S / R4S / N1 等 Armbian 系统）** 或 **PVE / ESXi 独立 Linux 虚拟机**，直接将该机器本身作为局域网旁路由网关时，推荐使用 **Host 网络模式** 一键部署：

```bash
# 1. 开启宿主机 IPv4 流量转发
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# 2. 使用 Host 网络模式一键启动 ROS-Box（直接接管物理机网卡作为透明旁路由网关）
docker run -d \
  --name ros-box \
  --restart always \
  --network host \
  --privileged \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -v /opt/rosbox/data:/opt/ROS-Box/data \
  -v /opt/rosbox/etc:/opt/ROS-Box/etc \
  -e TZ=Asia/Shanghai \
  -e PORT=2026 \
  fyasshole/ros-box:latest
```
> 启动后直接访问 `http://<物理机IP>:2026`，并将局域网设备的网关指向该物理机 IP 即可享受满血千兆透明代理加速。

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
- **全自动双端发布**：当检测到上游新版本发布时，自动触发多架构（`linux/amd64` 与 `linux/arm64`）镜像编译构建，生成与上游版本号一致的 **GitHub Releases 纯净 `.tar` 离线包**，并同步推送至 **Docker Hub (`fyasshole/ros-box`)** 与 **GHCR (`ghcr.io/zyeyefyass/ros-box`)**，实现永久无人值守自动同步。

---

## 📜 开源协议与致谢

- 本项目基于 **GPL-3.0** 协议开源。
- 特别鸣谢：
  - [liandu2024/Open-Box](https://github.com/liandu2024/Open-Box)
  - [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
  - [MikroTik RouterOS](https://mikrotik.com/)
