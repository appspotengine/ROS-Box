# ==============================================================================
# ROS-Box for RouterOS - 方案一：LAN 桥接旁路由模式 (Gateway Mode)
# 适用场景：局域网内设备可将网关/DNS指向 ROS-Box 容器 IP (例如 192.168.88.2)
# ==============================================================================

# ---- [配置变量] 请根据自身环境修改 ----
:local lanBridge "bridge"
:local diskName "disk1"
:local containerIp "192.168.88.2/24"
:local rosGateway "192.168.88.1"
:local imageName "your-docker-registry/ros-box:latest"

# 1. 创建 VETH 虚拟网卡并加入 LAN 网桥
/interface/veth
add name=veth-rosbox address=$containerIp gateway=$rosGateway

/interface/bridge/port
add bridge=$lanBridge interface=veth-rosbox comment="ROS-Box Container VETH"

# 2. 创建持久化存储挂载目录
/container/mounts
add name=rosbox-data src="$diskName/rosbox/data" dst="/opt/open-box/data"
add name=rosbox-etc src="$diskName/rosbox/etc" dst="/opt/open-box/etc"

# 3. 配置容器环境
/container/config
set registry-url=https://registry-1.docker.io tmpdir="$diskName/pull"

/container
add remote-image=$imageName \
    interface=veth-rosbox \
    root-dir="$diskName/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Gateway Proxy"

# 4. 打印后续提示
:put "=========================================================="
:put "ROS-Box 容器配置已完成！"
:put "1. 启动容器: /container/start [find comment=\"ROS-Box Gateway Proxy\"]"
:put "2. 浏览器访问面板: http://192.168.88.2:2026"
:put "3. 测试客户端请在设备上网卡手动配置："
:put "   - IP 地址: 192.168.88.x"
:put "   - 网关: 192.168.88.2"
:put "   - DNS: 192.168.88.2"
:put "=========================================================="
