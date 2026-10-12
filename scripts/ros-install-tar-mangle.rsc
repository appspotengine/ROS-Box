# ==============================================================================
# ROS-Box for RouterOS - 本地 .tar 离线导入 (独立网段 Mangle 策略分流模式)
# ==============================================================================

# ---- [配置变量] 请根据自身环境修改 ----
:local diskName "disk1"
:local tarFilePath "$diskName/ROS-Box-amd64.tar"
:local dockerBridge "bridge-docker"
:local rosDockerIp "172.16.1.1/24"
:local containerIp "172.16.1.2/24"
:local rosGateway "172.16.1.1"
:local lanSubnet "192.168.88.0/24"

# 1. 创建独立容器网桥与 IP
/interface/bridge
add name=$dockerBridge comment="Bridge for ROS-Box Container"

/ip/address
add address=$rosDockerIp interface=$dockerBridge comment="ROS Docker Gateway"

# 2. 创建 VETH 并桥接
/interface/veth
add name=veth-rosbox address=$containerIp gateway=$rosGateway

/interface/bridge/port
add bridge=$dockerBridge interface=veth-rosbox comment="ROS-Box VETH"

# 3. 创建出站 NAT 伪装
/ip/firewall/nat
add chain=srcnat action=masquerade src-address=172.16.1.0/24 comment="Container NAT"

# 4. 创建挂载卷
/container/mounts
add name=rosbox-data src="$diskName/rosbox/data" dst="/opt/open-box/data"
add name=rosbox-etc src="$diskName/rosbox/etc" dst="/opt/open-box/etc"

# 5. 从本地 .tar 文件创建容器
/container
add file=$tarFilePath \
    interface=veth-rosbox \
    root-dir="$diskName/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Mangle Tar Container"

# 6. 配置策略路由表与路由
/routing/table
add name=to-rosbox fib comment="Route to ROS-Box"

/ip/route
add dst-address=0.0.0.0/0 gateway=172.16.1.2 routing-table=to-rosbox comment="Route to ROS-Box"

# 7. 内网地址白名单
/ip/firewall/address-list
add list=LOCAL_SUBNETS address=10.0.0.0/8
add list=LOCAL_SUBNETS address=172.16.0.0/12
add list=LOCAL_SUBNETS address=192.168.0.0/16

# 8. Mangle 策略分流
/ip/firewall/mangle
add chain=prerouting src-address=$lanSubnet dst-address-list=!LOCAL_SUBNETS \
    connection-state=new action=mark-routing new-routing-mark=to-rosbox passthrough=yes \
    comment="Redirect Outbound traffic to ROS-Box"

# 9. DNS 劫持到容器 7853
/ip/firewall/nat
add chain=dstnat protocol=udp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=$lanSubnet comment="Redirect DNS UDP to ROS-Box"
add chain=dstnat protocol=tcp dst-port=53 action=dst-nat to-addresses=172.16.1.2 to-ports=7853 \
    src-address=$lanSubnet comment="Redirect DNS TCP to ROS-Box"

:put "=========================================================="
:put "策略分流容器添加任务已提交！"
:put "等待 RouterOS 解压完成后启动: /container/start [find comment=\"ROS-Box Mangle Tar Container\"]"
:put "浏览器访问面板: http://172.16.1.2:2026"
:put "=========================================================="
