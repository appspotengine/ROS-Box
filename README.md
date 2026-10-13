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

> ⚠️ **部署前通用说明（必看）**：
> 文档中出现的局域网网段示例均为 `192.168.88.x`（假设主路由网关是 `192.168.88.1`，分配给 ROS-Box 旁路由的空闲 IP 是 `192.168.88.2`）。**实际操作时，请务必将其替换为您自己局域网的真实网段与空闲 IP！**（例如您的主路由是 `10.0.0.1`，则将容器 IP 设为 `10.0.0.11/24`，网关设为 `10.0.0.1`）。

---

### 一、MikroTik RouterOS 7.x 部署（原生容器推荐）

#### 第一阶段：开启容器功能与基础网络准备（仅首次需执行）

1. **开启 RouterOS 容器功能**：
   在 WinBox 打开 **Terminal**，粘贴执行：
   ```routeros
   /system/device-mode/update container=yes
   ```
   执行后按终端提示：**拔插一次路由器电源（或按一下物理 Reset 键）**，或在虚拟机环境执行 `/system/reboot` 完成确认。

2. **关于存储路径（`disk1`）的重要说明**：
   - **大多数设备（x86 软路由 / PVE / ESXi / CHR / RB5009 / CCR 等内置空间充足设备）**：**无需外接 USB/硬盘**！下方命令会自动在内置存储根目录生成挂载点目录，离线 `.tar` 包直接存放在根目录即可，100% 避免路径不存在报错。
   - **小闪存设备（如仅 128MB 闪存的 hAP ax2/ax3）**：如内置空间不足以解压容器（解压后约 223 MiB），请插入 USB/SSD 并在 **System → Disks** 格式化为 **ext4**（假设盘符为 `disk1`，将下方命令中的文件路径加上 `disk1/` 前缀即可）。

3. **一键创建 VETH 虚拟网卡、网桥端口与持久化挂载卷**：
   打开 WinBox **Terminal**，修改第一行的容器 IP（`192.168.88.2/24`）与主路由网关（`192.168.88.1`）后整段粘贴执行（内置容错保护，重复执行不会报错）：
   ```routeros
   # 1. 创建 VETH 虚拟网卡（请将 192.168.88.2/24 和 192.168.88.1 改为您的实际局域网空闲 IP 与主路由 IP）
   :do { /interface/veth add name=veth-rosbox address=192.168.88.2/24 gateway=192.168.88.1 } on-error={}

   # 2. 将虚拟网卡加入局域网 Bridge 网桥（若您的主网桥名称不是 bridge，请修改 bridge= 参数）
   :do { /interface/bridge/port add bridge=bridge interface=veth-rosbox comment="ROS-Box Container VETH" } on-error={}

   # 3. 创建持久化数据与配置挂载卷（系统会自动创建对应目录，升级容器配置不丢失）
   :do { /container/mounts add name=rosbox-data src="disk1/rosbox/data" dst="/opt/ROS-Box/data" } on-error={}
   :do { /container/mounts add name=rosbox-etc src="disk1/rosbox/etc" dst="/opt/ROS-Box/etc" } on-error={}
   ```

---

#### 第二阶段：导入镜像并启动容器（四种方式任选其一）

##### 🇨🇳 方式 A：国内加速镜像直连一键拉取（纯命令行，无需科学上网 ⭐⭐⭐⭐⭐）
复制对应架构命令粘贴进 WinBox **Terminal** 回车，自动通过国内高速镜像下载最新离线包并创建容器：

- **1. x86 软路由 / PVE / ESXi / CHR 虚拟机 / 工控机 (`amd64` 架构)**：
  ```routeros
  /tool fetch url="https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-amd64.tar" dst-path="ROS-Box-amd64.tar" mode=https; /container add file=ROS-Box-amd64.tar interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
  ```
- **2. MikroTik RB5009 / CCR2004 / hAP ax2 / ax3 (`arm64` 架构)**：
  ```routeros
  /tool fetch url="https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-arm64.tar" dst-path="ROS-Box-arm64.tar" mode=https; /container add file=ROS-Box-arm64.tar interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
  ```

##### 💻 方式 B：电脑浏览器下载 + WinBox Files 拖拽导入（最稳妥，100% 零网络依赖）
如果路由器未配置 DNS 或无法联网，用电脑下载后拖入 WinBox 最快：
1. **在电脑浏览器点击下载离线包**：
   - 📦 **x86_64 (`amd64`)**：[国内加速下载 ROS-Box-amd64.tar](https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-amd64.tar) ｜ [GitHub 官方原链](https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-amd64.tar)
   - 📦 **ARM64 (`arm64`)**：[国内加速下载 ROS-Box-arm64.tar](https://ghproxy.net/https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-arm64.tar) ｜ [GitHub 官方原链](https://github.com/zyeyefyass/ROS-Box/releases/latest/download/ROS-Box-arm64.tar)
2. **拖拽上传**：打开 WinBox 左侧 **Files**，直接把下载好的 `ROS-Box-amd64.tar`（或 `ROS-Box-arm64.tar`）拖拽到 **Files 列表最顶层根目录**（若拖入了 `disk1` 文件夹内，请将下方 `file=` 改为 `disk1/ROS-Box-amd64.tar`）。
3. **导入容器**：在 Terminal 粘贴执行（ARM64 设备请将文件名改为 `ROS-Box-arm64.tar`）：
   ```routeros
   /container add file=ROS-Box-amd64.tar interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
   ```

##### ⚡ 方式 C：局域网电脑 HTTP 极速中转（千兆内网 3 秒拉取）
1. 在电脑存放 `.tar` 包的文件夹打开 PowerShell / CMD 运行：`python -m http.server 8000`
2. 在 RouterOS Terminal 执行（将 `192.168.88.10` 替换为您的电脑局域网 IP）：
   ```routeros
   /tool fetch url="http://192.168.88.10:8000/ROS-Box-amd64.tar" dst-path="ROS-Box-amd64.tar"; /container add file=ROS-Box-amd64.tar interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
   ```

##### 🌐 方式 D：Docker Hub 官方镜像在线拉取（适合海外或已有代理环境）
如果您的 RouterOS 可正常连接 Docker Hub，无需下载 `.tar`，直接拉取官方多架构镜像 `fyasshole/ros-box:latest`：
```routeros
/container/config set registry-url=https://registry-1.docker.io tmpdir="disk1/pull"
/container add remote-image=fyasshole/ros-box:latest interface=veth-rosbox root-dir=disk1/rosbox/root mounts=rosbox-data,rosbox-etc logging=yes start-on-boot=yes comment="ROS-Box"
```

#### 第三阶段：启动 RouterOS 容器
执行导入命令后，打开 WinBox 左侧 **Container** 窗口，观察容器状态从 `extracting` 变为 **`stopped`**（约需 5~10 秒），然后在 Terminal 执行启动命令（或在界面直接点击 **Start**）：
```routeros
/container/start [find comment="ROS-Box"]
```
启动后状态变为 `running`，浏览器直接访问 **`http://192.168.88.2:2026`**（您设定的容器 IP）即可进入管理面板！

---

### 二、NAS Docker（飞牛 fnOS / 群晖 / Unraid / CasaOS / 1Panel）部署

本项目已发布至 **Docker Hub ([`fyasshole/ros-box`](https://hub.docker.com/r/fyasshole/ros-box))** 与 **GitHub Container Registry (`ghcr.io/zyeyefyass/ros-box`)**，原生支持 `linux/amd64` 与 `linux/arm64` 双架构。

> 💡 **NAS 部署网络模式选择指南（关键防坑）**：
> 1. **Macvlan 独立 IP 模式（最推荐 ⭐⭐⭐⭐⭐）**：为容器分配局域网独立 IP（如飞牛 NAS 是 `192.168.88.10`，ROS-Box 是 `192.168.88.2`），彻底避免与 NAS 宿主机争抢 53 (DNS) 端口或污染宿主机路由表，体验等同于一台独立硬件旁路由。
>    *(注：若您的飞牛 fnOS / 群晖安装在 **PVE 或 ESXi 虚拟机** 内，使用 Macvlan 需在 PVE/ESXi 虚拟网卡设置中开启 **混杂模式 Promiscuous Mode**；若不想开启混杂模式，请直接使用下方的 **Host 网络模式**)*。
> 2. **Host 网络模式（最简单，适合虚拟机内安装的 NAS）**：容器直接共享 NAS 宿主机 IP（访问地址为 `http://<NAS_IP>:2026`，旁路由网关也指向 `<NAS_IP>`）。
> 3. **Bridge 端口映射模式**：⚠️ **注意**：Bridge 模式由于经过 Docker NAT 隔离，**不能**将容器作为局域网透明旁路由网关（TUN），仅能通过 `http://<NAS_IP>:7890` 在客户端软件中手动填写 HTTP/SOCKS5 代理使用。做透明旁路由请务必选 **Macvlan** 或 **Host**！

---

#### 方式 1：飞牛 fnOS 独立 IP（Macvlan）完整保姆级部署教程（强烈推荐 ⭐⭐⭐⭐⭐）

##### 第一步：在飞牛「镜像仓库」搜索下载镜像
1. 打开飞牛 fnOS 桌面 **Docker → 镜像仓库**；
2. 在顶部搜索框直接输入 **`ros-box`**（或 **`fyasshole/ros-box`**），点击下载官方镜像（标签选择 `latest`）。

##### 第二步：创建飞牛 Macvlan 独立局域网（仅首次需执行一次）
通过 SSH 登录飞牛 fnOS，执行以下 3 条命令创建 Macvlan 网络（请将 `192.168.88.0/24`、网关 `192.168.88.1`、固定分配 IP `192.168.88.2/32` 替换为您实际的局域网参数）：
```bash
# 1. 查看飞牛主网卡名称（例如 enp3s0、eth0；若飞牛开启了虚拟机网桥通常为 enp3s0-ovs）
ip route | grep default

# 2. 开启物理网卡混杂模式（请将 enp3s0 替换为第 1 步查到的实际网卡名）
sudo ip link set enp3s0 promisc on

# 3. 创建名为 macvlan-net 的独立网络（通过 --ip-range 锁定分配 192.168.88.2）
sudo docker network create -d macvlan \
  --subnet=192.168.88.0/24 \
  --gateway=192.168.88.1 \
  --ip-range=192.168.88.2/32 \
  -o parent=enp3s0 \
  macvlan-net
```
*(注：由于上一步添加了 `--ip-range=192.168.88.2/32`，无论您下面用 Compose 还是纯图形界面创建容器，Docker 都会 100% 自动将该容器固定在 `192.168.88.2`！)*

##### 第三步：启动容器（提供 Compose 与纯图形界面两种选法）

- **选法 A：通过飞牛「Compose → 新增项目」启动（最推荐，配置一目了然）**
  打开 **飞牛 Docker → Compose → 新增项目**，项目名称填 `ros-box`，选择存放路径后勾选 **「创建 docker-compose.yml」**，粘贴以下内容（将 `192.168.88.2` 改为您分配给 ROS-Box 的独立 IP）：
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
  点击创建并启动后，直接在浏览器访问 **`http://192.168.88.2:2026`** 即可进入 ROS-Box 控制台！

- **选法 B：通过飞牛「本地镜像 → 运行」纯图形化向导创建**
  1. 进入 **飞牛 Docker → 本地镜像**，找到下载好的 `fyasshole/ros-box:latest` 点击右侧 **「运行」**；
  2. **基础设置**：勾选 **「开机自启」**；展开高级设置，**务必勾选「使用最高权限执行容器 (Privileged)」**；
  3. **存储位置（文件夹映射）**：
     - 点击「添加路径」：选择飞牛本地新建的 `data` 文件夹 → 装载路径填 **`/opt/ROS-Box/data`**（权限：读写）
     - 点击「添加路径」：选择飞牛本地新建的 `etc` 文件夹 → 装载路径填 **`/opt/ROS-Box/etc`**（权限：读写）
  4. **网络**：下拉选择刚刚创建的 **`macvlan-net`**（若不想用 Macvlan，也可在此直接选择 **`host`** 模式，此时访问地址与网关均为 `飞牛宿主机IP`）；
  5. 点击完成创建即可一键启动！

---

#### 方式 2：通用 Docker Compose 部署（Host 旁路由模式）
如果您在飞牛 fnOS / 群晖 / Unraid 上不想配置 Macvlan（或 NAS 运行在未开启混杂模式的虚拟机中），可直接使用 **Host 网络模式** 的 `docker-compose.yml`：
```yaml
services:
  ros-box:
    image: fyasshole/ros-box:latest
    container_name: ros-box
    restart: always
    network_mode: host
    privileged: true
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ./data:/opt/ROS-Box/data
      - ./etc:/opt/ROS-Box/etc
    environment:
      - TZ=Asia/Shanghai
      - PORT=2026
      - OPENBOX_PLATFORM=container
```

---

### 三、Linux 物理机 / 虚拟机（Debian / Ubuntu / Armbian / PVE）旁路由部署

如果您使用的是 **x86 软路由小主机（N100 / J4125 等）**、**ARM 旁路由盒子（R2S / R4S / N1 等 Armbian 系统）** 或 **PVE / ESXi 独立 Linux 虚拟机**，直接将该机器本身作为局域网透明旁路由网关时，执行以下命令即可一键完成部署：

```bash
# 1. 开启宿主机 IPv4 流量转发（作为旁路由网关必开）
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# 2. 使用 Host 网络模式一键启动 ROS-Box（直接接管物理机网卡作为透明旁路由网关）
sudo docker run -d \
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
> 启动后直接访问 **`http://<物理机IP>:2026`** 进入管理面板，局域网设备将 **网关** 与 **DNS** 指向该 `<物理机IP>` 即可享受满血千兆透明代理加速。

---

## 💻 控制台初始化与局域网设备接入指南

### 🎬 官方操作演示视频（YouTube 教程参考）
面板的订阅配置、策略分流、DNS 防泄露、链式代理及多端客户端配对操作与上游 Open-Box 完全一致，可参考以下官方视频演示（建议**右键「在新标签页中打开」**或按住 `Ctrl` / `⌘` 点击）：

1. 📺 [最新软路由代理 Open-Box 发布！全图形极简配置，超越 OpenClash/Nikki/Passwall + SubStore + Zashboard？](https://youtu.be/G_7AmjfSRQ8)
2. 📺 [集成 ADGuard Home + 故障转移 + 解决 Google Play 无法下载，Open-Box 更新了啥？](https://youtu.be/fczlXs2t5tI)
3. 📺 [魔改 Sing-Box 1.14 内核，直连提速 200%！等同 Dae 性能，绝无 DNS 泄露 + 链式代理，Open-Box 完整体来了！](https://youtu.be/5_Z9d2zyzAw)
4. 📱 [Open-Box 客户端 Android 来啦！真一键配置 + 完美分流，绝无 DNS 泄露，是时候卸载 Karing/ClashMi 等其他代理 App 了](https://youtu.be/NVUssX8ILxE)
5. 🖥️ [Windows/macOS 来了，Open-Box 客户端，真一键配置 + 完美分流，绝无 DNS 泄露，生产力平台哪能缺席？](https://youtu.be/A1yFmwQLES4)

---

### 第一步：初始化 ROS-Box 控制台并启动内核
1. **登录面板**：打开浏览器访问 **`http://<ROS-Box_IP>:2026`**（例如 `http://192.168.88.2:2026`），首次打开时设置管理员登录密码；
2. **添加订阅与节点**：进入 **「设置 → 订阅管理」**，粘贴机场订阅链接（支持 Clash YAML、Base64 分享链接及各类 Sing-Box 节点协议）并拉取更新；
3. **配置节点组与目标分流**：
   - **「设置 → 出站节点」**：可按关键词建立动态自动择优组（url-test）、手动选择组（select）或主备故障转移组；
   - **「设置 → 目标分流」**：按站点集配置直连或代理出口（切换策略时秒级热重载，不中断已有连接）；
4. **启动内核服务**：在 **「设置 → 后端设置」**（或顶部状态栏）点击启动内核服务，回到 **「概览」** 页即可实时查看四站点延迟走势、连接数与流量曲线。

### 第二步：让局域网设备接入透明代理（三种方式按需选择）
- **选法 1：单台设备按需接入（最稳妥，不影响家人日常上网）**
  在需要科学上网的电脑或手机 Wi-Fi 设置中，将 IP 改为 **手动 (静态)**：
  - **IP 地址**：填设备原本的局域网 IP（如 `192.168.88.50`）
  - **子网掩码**：`255.255.255.0`（或前缀长度 `24`）
  - **默认网关 (Gateway)**：填 **ROS-Box 的 IP**（如 `192.168.88.2`）
  - **DNS 服务器**：填 **ROS-Box 的 IP**（如 `192.168.88.2`）
- **选法 2：全屋设备自动无感接入（主路由 DHCP 统一下发）**
  打开主路由器的 **DHCP Server → Networks** 设置：
  - 将 **Gateway（默认网关）** 与 **DNS Server** 均修改为 **ROS-Box 的 IP**（如 `192.168.88.2`）；
  - 局域网设备重连一次 Wi-Fi 即可自动走旁路由透明分流（也可在面板 **「终端分流」** 中为特定设备单独指定「直连」或「不进内核」）。
- **选法 3：搭配全平台客户端（Android / Windows / macOS / Linux）同步分流**
  在面板 **「设置 → 客户端」** 中可直接下载对应系统客户端，通过扫描面板二维码一键导入全套订阅节点与分流规则，在外网环境下同样享受与家里旁路由一致的零泄露分流体验。

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
