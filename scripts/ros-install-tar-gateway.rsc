# ==============================================================================
# ROS-Box for RouterOS - 本地 .tar 离线导入 (旁路由 LAN 桥接模式)
# 对应视频教程类似操作：通过 WinBox 上传 .tar 文件后本地导入创建容器
# ==============================================================================

# ---- [配置变量] 请根据自身环境修改 ----
:local lanBridge "bridge"
:local diskName "disk1"
# 上传到磁盘的 tar 包文件名 (例如 disk1/ROS-Box-amd64.tar 或 disk1/ROS-Box-arm64.tar)
:local tarFilePath "$diskName/ROS-Box-amd64.tar"
:local containerIp "192.168.88.2/24"
:local rosGateway "192.168.88.1"

# 1. 创建 VETH 网卡并桥接至 LAN
/interface/veth
add name=veth-rosbox address=$containerIp gateway=$rosGateway

/interface/bridge/port
add bridge=$lanBridge interface=veth-rosbox comment="ROS-Box Container VETH"

# 2. 创建持久化挂载目录
/container/mounts
add name=rosbox-data src="$diskName/rosbox/data" dst="/opt/ROS-Box/data"
add name=rosbox-etc src="$diskName/rosbox/etc" dst="/opt/ROS-Box/etc"

# 3. 使用本地 .tar 文件创建容器 (注意：使用 file= 参数而不是 remote-image)
/container
add file=$tarFilePath \
    interface=veth-rosbox \
    root-dir="$diskName/rosbox/root" \
    mounts=rosbox-data,rosbox-etc \
    logging=yes \
    start-on-boot=yes \
    comment="ROS-Box Tar Container"

:put "=========================================================="
:put "容器添加任务已提交！"
:put "RouterOS 正在解压 tar 包，请在 WinBox Container 列表中观察状态："
:put "状态从 extracting... 变为 stopped 即表示解压完成。"
:put "解压完成后启动容器: /container/start [find comment=\"ROS-Box Tar Container\"]"
:put "之后通过浏览器访问面板: http://192.168.88.2:2026"
:put "=========================================================="
