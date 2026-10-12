# RouterOS 7.x 容器离线 .tar 导入安装指南

本指南指导您如何将 ROS-Box 导出的 `.tar` 离线镜像文件直接上传至 RouterOS 本地存储，并通过 WinBox 快速完成容器导入与启动。

---

## 🌟 为什么推荐使用 `.tar` 离线文件安装？

1. **摆脱网络环境困扰**：RouterOS 直接从公共 Registry 拉取镜像极易受网络环境影响导致超时或卡在 `pulling 0%`。
2. **无需注册与配置 Registry**：不需要在 RouterOS 内配置任何 Docker 仓库账号或代理源。
3. **零门槛 WinBox 纯鼠标操作**：只需将 `.tar` 文件直接拖拽进 WinBox Files，图形化点击即可完成部署。

---

## 1. 准备 .tar 镜像文件

### 1.1 确认您的路由器架构
登录 WinBox，点击 **System → Resources**，查看 **Architecture Name**：
- **x86_64 / chr**（PC 软路由、PVE/ESXi 虚拟机、CHR 等） 👉 选用 **`ROS-Box-amd64.tar`**
- **arm64**（MikroTik RB5009、CCR2004、CCR2116、hAP ax2/ax3 等） 👉 选用 **`ROS-Box-arm64.tar`**

### 1.2 获取或打包 .tar 文件

#### 方式 A：直接下载 Release 预编译包（最快）
访问 GitHub Releases 页面，直接下载最新版本的 `ROS-Box-amd64.tar` 或 `ROS-Box-arm64.tar`。

#### 方式 B：在本地电脑一键生成（需要 Docker Desktop）
在本项目根目录下：
- **Windows 用户**：运行脚本
  ```cmd
  scripts\package-tar.bat amd64     # 生成 x86/CHR 镜像
  # 或
  scripts\package-tar.bat arm64     # 生成 ARM64 镜像
  ```
- **Linux / macOS 用户**：运行脚本
  ```bash
  chmod +x scripts/package-tar.sh
  ./scripts/package-tar.sh amd64    # 或 arm64 / all
  ```

---

## 2. WinBox 图形界面分步实操

### 第一步：开启容器功能与格式化磁盘
1. 打开 WinBox，打开 **Terminal**，执行：
   ```routeros
   /system/device-mode/update container=yes
   ```
   按提示按下设备物理 Reset 键或执行 `/system/reboot` 确认。
2. 插入 USB 移动硬盘或 MicroSD 卡（建议大于 2GB），进入 **System → Disks**，格式化为 **ext4** 文件系统（假设盘符识别为 `disk1`）。

---

### 第二步：拖拽上传 .tar 镜像到路由器
1. 打开 WinBox 左侧菜单 **Files** 窗口；
2. 找到您的外置存储目录（例如 `disk1`）；
3. 直接将电脑中的 **`ROS-Box-amd64.tar`** 文件拖拽上传到 `disk1` 目录下。

---

### 第三步：配置 VETH 虚拟网卡
1. 点击左侧菜单 **Interfaces**，切换到 **VETH** 选项卡；
2. 点击 **`+`** 号新建：
   - **Name**: `veth-rosbox`
   - **Address**: `192.168.88.2/24`（给容器分配的 IP，须与 LAN 同网段且不冲突）
   - **Gateway**: `192.168.88.1`（RouterOS 的 LAN IP）
3. 点击 **OK** 保存。
4. 点击左侧菜单 **Bridge**，切换到 **Ports** 选项卡：
   - 点击 **`+`** 号新建；
   - **Interface**: 选择 `veth-rosbox`；
   - **Bridge**: 选择 `bridge`（您的主局域网网桥）；
   - 点击 **OK** 保存。

---

### 第四步：配置存储挂载卷 (Mounts)
确保容器配置与数据在重启后不丢失：
1. 打开 **Container** 菜单，切换到 **Mounts** 选项卡；
2. 点击 **`+`** 号创建数据挂载点：
   - **Name**: `rosbox-data`
   - **Src**: `disk1/rosbox/data`
   - **Dst**: `/opt/open-box/data`
   - 点击 **OK**；
3. 再次点击 **`+`** 号创建配置挂载点：
   - **Name**: `rosbox-etc`
   - **Src**: `disk1/rosbox/etc`
   - **Dst**: `/opt/open-box/etc`
   - 点击 **OK**。

---

### 第五步：从 .tar 文件创建容器
1. 回到 **Container** 菜单的主选项卡（**Containers** 列表）；
2. 点击 **`+`** 号新建容器：
   - **File**: 点击下拉框，选中上传的 **`disk1/ROS-Box-amd64.tar`**
   - **Interface**: 选择 **`veth-rosbox`**
   - **Root Dir**: 填入 **`disk1/rosbox/root`**
   - **Mounts**: 选中 **`rosbox-data`** 和 **`rosbox-etc`**
   - **Logging**: 勾选 `yes`
   - **Start on Boot**: 勾选 `yes`
3. 点击 **OK** 或 **Apply**。

---

### 第六步：等待解压并启动
1. 此时观察 Container 列表中的 **Status** 列：
   - 初始状态显示为 **`extracting...`**（RouterOS 正在将 tar 包解压到外置磁盘中，耗时约 30 秒至 2 分钟，取决于存储介质速度）；
2. 当状态变为 **`stopped`** 时，说明解压完成！
3. 选中该容器，点击上方的 **`Start`** 按钮；
4. 状态变为 **`running`**，容器启动成功！
   *(解压完成后，`disk1/ROS-Box-amd64.tar` 文件即可从 Files 窗口中删除以节约磁盘空间)*。

---

### 第七步：进入 ROS-Box Web 面板
1. 打开浏览器，输入：
   ```text
   http://192.168.88.2:2026
   ```
2. **首次访问设置密码**：输入您自定义的管理密码；
3. 进入面板后，依次配置订阅、出站节点、分流规则；
4. 点击右上角 **“部署 / 启动内核”** 即可！

---

## 3. 终端设备快速接入测试

想要让某台电脑或手机走 ROS-Box 代理：
1. 打开该设备的网络设置；
2. 将 IPv4 从 DHCP 改为手动：
   - **IP 地址**：`192.168.88.188`（或任意可用内网 IP）
   - **子网掩码**：`255.255.255.0`
   - **默认网关**：**`192.168.88.2`**（指向 ROS-Box 容器）
   - **DNS 服务器**：**`192.168.88.2`**（由 ROS-Box 内核防污染解析）
3. 立即打开浏览器测试国内外网站，即可实现极速透明代理分流！
