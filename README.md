# ROS-Box (RouterOS Appliance)

<p align="center">
  <img src="panel/dist/logo-orbit.svg" alt="ROS-Box Logo" width="128" height="128" />
</p>

<p align="center">
  <strong>专为 MikroTik RouterOS 7.x 深度定制的高性能、超轻量旁路由透明代理容器系统</strong><br>
  <em>RouterOS Container Native • Sing-Box 1.14 Core • Sub-60MiB RAM • Self-Healing Networking</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/RouterOS-v7.4~v7.24+-004e82.svg?logo=mikrotik&logoColor=white" alt="RouterOS" />
  <img src="https://img.shields.io/badge/Sing--Box-v1.14-00d2ff.svg" alt="Sing-Box" />
  <img src="https://img.shields.io/badge/Architecture-amd64%20%7C%20arm64-38bdf8.svg" alt="Arch" />
  <img src="https://img.shields.io/badge/Memory-45~55MiB%20Idle-10b981.svg" alt="Memory" />
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue.svg" alt="License" />
</p>

---

## 🌟 核心特性与创新

1. **RouterOS Container 专属定制**：
   - 彻底脱离 OpenWrt 的 `uci` / `ubus` / `fw4` / `dnsmasq` 及 Linux `systemd` 宿主依赖。
   - 专为 MikroTik RouterOS 容器沙盒设计独立的生命周期控制层与日志管道。

2. **RouterOS 7.22+ 策略路由缺陷自愈 (Self-Healing `ip rule`)**：
   - 针对 RouterOS 7.22+ 默认注入的 `1: local`, `2: main`, `3: default` 冲突规则，内置启动期与运行期策略路由自愈引擎，彻底解决 TUN 模式流量被 ROS 宿主拦截的行业痛点。

3. **极致内存与体积控制 (Ultra-Low Footprint)**：
   - 单进程内存软上限限制在 `GOMEMLIMIT=60MiB`，空闲运行内存仅需 **45 ~ 55 MiB**，完美契合 RB5009、hAP ax2/ax3 等有限内存设备。
   - 纯净生产构建，单层高压打包，容器离线 `.tar` 仅约 **220MB**（`.tar.gz` 仅 **87MB**）。

4. **原生多硬件架构支持 (Multi-Architecture)**：
   - **`linux/amd64`**：适用 PC 软路由、x86 工控机、PVE/ESXi 虚拟机、CHR。
   - **`linux/arm64`**：适用 MikroTik 官方硬件（RB5009、CCR2004、CCR2116、hAP ax2/ax3 等）。

5. **MikroTik 专属视觉美学与纯净体验**：
   - 采用 MikroTik 科技深蓝设计语言（`#002d50`、`#004e82`、`#00d2ff`），搭配 3D 动力晶体双环 Logo。
   - 彻底剔除所有第三方商业推广、社交引流及多余外链，专注极速网络转发。

---

## 📂 项目结构

```text
ROS-Box/
├── Dockerfile                   # 多架构 Alpine + Node 22 容器镜像构建文件
├── docker-compose.yml           # 本地/服务器调试配置
├── entrypoint.sh                # 容器启动入口 (TUN 初始化、ip rule 修复、进程调度)
├── bin/
│   ├── amd64/sing-box           # x86_64 预编译 sing-box 1.14 内核
│   └── arm64/sing-box           # aarch64 预编译 sing-box 1.14 内核
├── container/
│   ├── bin/
│   │   ├── openbox-ctl          # 容器内核守护与控制服务脚本 (start/stop/restart/status)
│   │   └── openbox-panel-ctl    # 面板状态守护脚本
│   └── shim/
│       └── logread              # 容器环境 logread 接口模拟器
├── panel/
│   ├── dist/                    # 编译完成的前端 Web 管理面板 (Vue 3 + Vite)
│   └── server/                  # Node.js ESM 后端服务源码
│       ├── api/                 # 面板 REST API 路由
│       ├── engine/              # sing-box 配置生成与分流引擎
│       ├── system/              # 系统适配层 (ROS 容器平台适配)
│       └── resources/geodata/   # 离线 GeoSite/GeoIP 规则数据库
├── scripts/
│   ├── build-docker.bat         # Windows Docker 镜像构建脚本
│   ├── build-docker.sh          # Linux/macOS Docker 构建脚本
│   ├── package-tar.bat          # Windows 一键导出 RouterOS 离线 .tar 镜像
│   ├── package-tar.sh           # Linux/macOS 一键导出 RouterOS 离线 .tar 镜像
│   ├── ros-install-tar-gateway.rsc # RouterOS 本地 .tar 旁路由模式一键导入
│   ├── ros-install-tar-mangle.rsc  # RouterOS 本地 .tar 策略分流模式一键导入
│   ├── ros-setup-gateway.rsc    # RouterOS 旁路由模式在线导入脚本
│   └── ros-setup-mangle.rsc     # RouterOS 策略分流模式在线导入脚本
└── docs/
    ├── ARCHITECTURE.md          # 架构改造与二次开发技术剖析
    ├── ROUTEROS_DEPLOY_GUIDE.md # RouterOS 7.x 完整部署与拓扑实战指南
    └── ROUTEROS_TAR_INSTALL_GUIDE.md # WinBox 拖拽导入 .tar 离线安装实操手册
```

---

## 🚀 快速上手部署

### 准备工作：开启 RouterOS 容器功能

在 WinBox 打开 **Terminal**，执行：

```routeros
/system/device-mode/update container=yes
```

> **注意**：执行后根据路由器提示按下物理 Reset 键或在 3-5 分钟内执行 `/system/reboot` 重启生效。建议将外置 USB/SSD 格式化为 `ext4` 分区挂载。

---

### 部署方式一：通过 WinBox 本地上传 `.tar` 导入（强烈推荐）

1. 从 [Releases](../../releases) 下载对应架构的离线镜像包（例如 `ROS-Box-amd64.tar` 或 `ROS-Box-arm64.tar`）；
2. 打开 WinBox，将 `.tar` 文件直接拖拽上传至外置存储路径（例如 `disk1/`）；
3. 打开 WinBox Terminal，执行一键导入命令（以旁路由模式为例）：

```routeros
/import file=disk1/scripts/ros-install-tar-gateway.rsc
```

或者手动在 WinBox **Container** 中点击 **Add**：
- **File**：选择 `disk1/ROS-Box-amd64.tar`
- **Interface**：指定提前创建好的 `veth-rosbox`
- **Root Dir**：`disk1/rosbox/root`
- **Mounts**：添加 `rosbox-data` (`/opt/open-box/data`) 与 `rosbox-etc` (`/opt/open-box/etc`)
- **Logging**：勾选 `yes`

4. 等待 RouterOS 解压完成（状态由 `extracting...` 变为 `stopped`）；
5. 选中容器点击 **Start** 启动。

---

### 部署方式二：通过 Registry 在线拉取部署

在 RouterOS 终端中运行：

```routeros
/import file=scripts/ros-setup-gateway.rsc
```

---

## 💻 访问与管理

1. 打开浏览器访问：`http://<容器IP>:2026`（例如 `http://192.168.88.2:2026`）；
2. 首次进入请设置管理员登录密码；
3. 进入 **订阅管理** 添加节点订阅链接；
4. 进入 **设置中心** 选择分流规则模式，点击右上角 **部署 / 启动内核**。

---

## 🛠️ 自行打包构建

如果您需要基于源代码自行编译构建：

### 本地打包导出 RouterOS `.tar` 镜像

- **Windows 用户**：
  ```cmd
  scripts\package-tar.bat amd64     # 导出 x86_64 离线镜像 ROS-Box-amd64.tar
  scripts\package-tar.bat arm64     # 导出 ARM64 离线镜像 ROS-Box-arm64.tar
  ```

- **Linux / macOS 用户**：
  ```bash
  chmod +x scripts/*.sh
  ./scripts/package-tar.sh amd64    # 或 arm64 / all
  ```

### 云端自动构建 (GitHub Actions)

仓库已内置 [`.github/workflows/build-tar.yml`](.github/workflows/build-tar.yml)，推送到 GitHub 或发布 Release Tag 时，GitHub Actions 会全自动并行交叉编译并生成多架构的 `.tar` 安装包与 SHA256 校验码。

---

## 📜 开源协议

本项目基于 GPL-3.0 协议开源发布。
原项目致谢：[liandu2024/Open-Box](https://github.com/liandu2024/Open-Box) & [SagerNet/sing-box](https://github.com/SagerNet/sing-box)。
