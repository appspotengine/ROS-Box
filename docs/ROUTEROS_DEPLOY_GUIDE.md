# MikroTik RouterOS 7.x 部署 ROS-Box 完整实战教程

本教程指导您如何在 MikroTik RouterOS 7.x（支持 ARM64、x86/CHR）中，通过容器功能快速部署 ROS-Box。

---

## 目录
1. [环境准备](#1-环境准备)
2. [部署方案选型](#2-部署方案选型)
3. [方案一：LAN 桥接旁路由模式（推荐，极简）](#3-方案一lan-桥接旁路由模式推荐极简)
4. [方案二：Mangle 策略分流模式（高级，设备无需改网关）](#4-方案二mangle-策略分流模式高级设备无需改网关)
5. [首次进入与配置 ROS-Box 面板](#5-首次进入与配置-ros-box-面板)
6. [常见问题与排错指南](#6-常见问题与排错指南)

---

## 1. 环境准备

### 1.1 开启 RouterOS 容器支持
RouterOS 需为 7.4 及以上版本。在终端中执行：
```routeros
/system/device-mode/update container=yes
```
执行后 RouterOS 会提示您按下设备物理 Reset 键或在 3-5 分钟内执行重启以确认开启：
```routeros
/system/reboot
```

### 1.2 准备外置存储
容器解压与数据读写需要较多空间，强烈建议使用外接 USB 驱动器、NVMe SSD 或 MicroSD 卡，并将其格式化为 `ext4`：
1. 插入存储介质；
2. 在 WinBox 中进入 **System → Disks**；
3. 选中磁盘（如 `usb1` 或 `disk1`），点击 **Format Drive**，文件系统选择 **ext4**。

---

## 2. 部署方案选型

| 模式 | 客户端设置 | 灵活性 | 复杂度 | 推荐人群 |
| :--- | :--- | :--- | :--- | :--- |
| **方案一：LAN 桥接旁路由模式** | 需指定网关与 DNS 为容器 IP | 极高，单机测试互不影响 | ⭐ 简单 | 大多数家庭/小型网络 |
| **方案二：Mangle 策略路由模式** | 客户端无需任何修改 | 全局/分流透明分流 | ⭐⭐⭐ 中等 | 进阶 RouterOS 玩家 |

---

## 3. 方案一：LAN 桥接旁路由模式（推荐，极简）

在此方案中，ROS-Box 容器直接连接到主 LAN 网桥（如 `bridge`），与内网电脑/手机处于同一局域网网段（例如 `192.168.88.x`）。

### 3.1 创建 VETH 网卡并接入网桥
假设主路由 IP 为 `192.168.88.1`，为容器分配 IP `192.168.88.2`：
```routeros
# 创建虚拟网卡
/interface/veth
add name=veth-rosbox address=192.168.88.2/24 gateway=192.168.88.1

# 将网卡加入 LAN 网桥 (假设您的网桥名为 bridge)
/interface/bridge/port
add bridge=bridge interface=veth-rosbox comment="ROS-Box Container"
```

### 3.2 配置存储挂载点与镜像仓库
假设外置存储路径为 `disk1`：
```routeros
# 创建持久化挂载卷
/container/mounts
add name=rosbox-data src="disk1/rosbox/data" dst="/opt/open-box/data"
add name=rosbox-etc src="disk1/rosbox/etc" dst="/opt/open-box/etc"

# 配置拉取源 (国内用户可配置镜像代理)
/container/config
set registry-url=https://registry-1.docker.io tmpdir="disk1/pull"
```

### 3.3 创建并启动容器
```routeros
/container
add remote-image="your-registry/ros-box:latest" \
    interface=veth-rosbox \
    root-dir="disk1/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Container"

# 启动容器
/container/start [find comment="ROS-Box Container"]
```

> **客户端接入**：
> 电脑或手机网卡手动设置：
> - IP 地址：`192.168.88.100`（或其他可用 IP）
> - 子网掩码：`255.255.255.0`
> - 默认网关：`192.168.88.2`（指向 ROS-Box 容器）
> - 首选 DNS：`192.168.88.2`（由 ROS-Box 解析分流）

---

## 4. 方案二：Mangle 策略分流模式（高级，设备无需改网关）

在此方案中，容器置于独立子网（例如 `172.16.1.0/24`），内网所有设备依然将网关指向 RouterOS（`192.168.88.1`），由 RouterOS 防火墙根据规则智能将流量转交给容器。

### 4.1 创建容器子网与 VETH
```routeros
# 创建专有网桥
/interface/bridge add name=bridge-docker comment="Docker Subnet Bridge"
/ip/address add address=172.16.1.1/24 interface=bridge-docker comment="ROS Docker Gateway"

# 创建 VETH
/interface/veth add name=veth-rosbox address=172.16.1.2/24 gateway=172.16.1.1
/interface/bridge/port add bridge=bridge-docker interface=veth-rosbox

# 容器基础出网 NAT
/ip/firewall/nat add chain=srcnat action=masquerade src-address=172.16.1.0/24 comment="Docker Outbound NAT"
```

### 4.2 创建容器
```routeros
/container/mounts
add name=rosbox-data src="disk1/rosbox/data" dst="/opt/open-box/data"
add name=rosbox-etc src="disk1/rosbox/etc" dst="/opt/open-box/etc"

/container
add remote-image="your-registry/ros-box:latest" \
    interface=veth-rosbox \
    root-dir="disk1/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Container"

/container/start [find comment="ROS-Box Container"]
```

### 4.3 RouterOS 策略路由配置 (v7.x)
```routeros
# 1. 创建策略路由表
/routing/table add name=to-rosbox fib comment="Route table to ROS-Box"

# 2. 增加默认路由到容器
/ip/route add dst-address=0.0.0.0/0 gateway=172.16.1.2 routing-table=to-rosbox comment="Route to ROS-Box"

# 3. 建立局域网内网地址表 (排除内网互访)
/ip/firewall/address-list
add list=LOCAL_SUBNETS address=10.0.0.0/8
add list=LOCAL_SUBNETS address=172.16.0.0/12
add list=LOCAL_SUBNETS address=192.168.0.0/16

# 4. Mangle 策略分流 (抓取去往外网的流量送入 to-rosbox 表)
/ip/firewall/mangle
add chain=prerouting src-address=192.168.88.0/24 dst-address-list=!LOCAL_SUBNETS \
    connection-state=new action=mark-routing new-routing-mark=to-rosbox passthrough=yes \
    comment="Redirect LAN traffic to ROS-Box"

# 5. 将内网 DNS 劫持到 ROS-Box 内核 DNS
/ip/firewall/nat
add chain=dstnat protocol=udp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=192.168.88.0/24 comment="Redirect DNS UDP to ROS-Box"
add chain=dstnat protocol=tcp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=192.168.88.0/24 comment="Redirect DNS TCP to ROS-Box"
```

---

## 5. 首次进入与配置 ROS-Box 面板

1. 打开浏览器，输入容器对应 IP 的 `2026` 端口：
   - 方案一：`http://192.168.88.2:2026`
   - 方案二：`http://172.16.1.2:2026`
2. **首次设置管理员密码**（请牢记密码）。
3. 进入 **订阅管理**：
   - 添加您的订阅链接（支持 Clash YAML / Base64 / Sing-Box 分享链接）。
4. 进入 **目标分流** 与 **出站节点**：
   - 设置国外站点走代理、国内站点直连。
5. 点击右上角 **部署 / 启动内核**。
   - ROS-Box 会自动根据节点生成 sing-box 配置，并拉起后台代理进程。

---

## 6. 常见问题与排错指南

### Q1: 容器启动了，但终端日志显示 `sing-box: file exists` 或 `auto_redirect failed`？
- **原因**：RouterOS 7.22 及以上版本在容器内默认注入了高优先级的系统路由规则（`1: local`, `2: main`, `3: default`）。
- **已解决**：本项目在 `container/bin/openbox-ctl` 和 `entrypoint.sh` 中已内置了自动优先级修复补丁，容器启动时会自动抹除 1/2/3 号规则并重排为合法标准优先级，无需手动执行脚本。

### Q2: 出现 `open /dev/net/tun: no such file or directory`？
- **检查**：请确保 RouterOS 运行在支持 TUN 的版本（7.4+），且容器启动脚本有权限。我们的 `entrypoint.sh` 会自动执行 `mknod /dev/net/tun c 10 200`，无需宿主机额外干预。

### Q3: 为什么外置磁盘空间报错，容器无法拉取？
- **原因**：RouterOS 内部 Flash 空间通常极小（如 16MB/32MB/128MB）。必须在 `/container/config` 将 `tmpdir` 设置在外置磁盘（例如 `disk1/pull`），且磁盘必须格式化为 `ext4`。
