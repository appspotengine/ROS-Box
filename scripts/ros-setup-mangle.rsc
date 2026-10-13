# ==============================================================================
# ROS-Box for RouterOS - 方案二：独立网段 Mangle 策略分流模式 (Policy Routing Mode)
# 适用场景：客户端无需修改网关与 DNS，仍指向 RouterOS (192.168.88.1)
# RouterOS 通过 Mangle 规则将流量策略路由至 ROS-Box 容器。
# ==============================================================================

# ---- [配置变量] 请根据自身环境修改 ----
:local diskName "disk1"
:local dockerBridge "bridge-docker"
:local rosDockerIp "172.16.1.1/24"
:local containerIp "172.16.1.2/24"
:local rosGateway "172.16.1.1"
:local lanSubnet "192.168.88.0/24"
:local imageName "fyasshole/ros-box:latest"

# 1. 创建独立容器网桥与 IP
/interface/bridge
add name=$dockerBridge comment="Bridge for ROS-Box Container"

/ip/address
add address=$rosDockerIp interface=$dockerBridge comment="RouterOS Container Gateway"

# 2. 创建 VETH 并加入容器网桥
/interface/veth
add name=veth-rosbox address=$containerIp gateway=$rosGateway

/interface/bridge/port
add bridge=$dockerBridge interface=veth-rosbox comment="ROS-Box Container VETH"

# 3. 创建出站 NAT (Masquerade) 确保容器可访问外网
/ip/firewall/nat
add chain=srcnat action=masquerade src-address=172.16.1.0/24 comment="NAT for Container Network"

# 4. 创建持久化存储挂载目录
/container/mounts
add name=rosbox-data src="$diskName/rosbox/data" dst="/opt/ROS-Box/data"
add name=rosbox-etc src="$diskName/rosbox/etc" dst="/opt/ROS-Box/etc"

# 5. 配置容器环境
/container/config
set registry-url=https://registry-1.docker.io tmpdir="$diskName/pull"

/container
add remote-image=$imageName \
    interface=veth-rosbox \
    root-dir="$diskName/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Policy Routing Proxy"

# 6. 配置策略路由表 (RouterOS 7.x)
/routing/table
add name=to-rosbox fib comment="Route table to ROS-Box Container"

/ip/route
add dst-address=0.0.0.0/0 gateway=172.16.1.2 routing-table=to-rosbox comment="Default route for ROS-Box"

# 7. 配置内网私网地址列表 (避免局域网互访进代理)
/ip/firewall/address-list
add list=LOCAL_SUBNETS address=10.0.0.0/8 comment="Private LAN"
add list=LOCAL_SUBNETS address=172.16.0.0/12 comment="Private LAN"
add list=LOCAL_SUBNETS address=192.168.0.0/16 comment="Private LAN"

# 8. Mangle 策略分流示例 (抓取内网非私网流量打上 to-rosbox 路由标记)
/ip/firewall/mangle
add chain=prerouting src-address=$lanSubnet dst-address-list=!LOCAL_SUBNETS \
    connection-state=new action=mark-routing new-routing-mark=to-rosbox passthrough=yes \
    comment="Route outbound LAN traffic to ROS-Box"

# 9. 可选：劫持内网 DNS 查询重定向到 ROS-Box 内核 DNS (7853 端口)
/ip/firewall/nat
add chain=dstnat protocol=udp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=$lanSubnet comment="Redirect DNS UDP to ROS-Box"
add chain=dstnat protocol=tcp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=$lanSubnet comment="Redirect DNS TCP to ROS-Box"

:put "=========================================================="
:put "ROS-Box 策略分流容器配置完成！"
:put "面板访问地址: http://172.16.1.2:2026"
:put "=========================================================="
