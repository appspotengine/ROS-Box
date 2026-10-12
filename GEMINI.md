# ROS-Box Project Rules & Guidelines

## 1. 自动授权与全自主执行准则 (Autonomous Authorization Policy)
- **零人工授权中断**：严禁在命令行执行、文件读写、测试构建、镜像打包或网络测试过程中要求用户手动点击授权或提交。所有工具调用和常规操作默认获得最高权限全自动执行。
- **自愈与闭环验证**：遇到错误（如语法错误、网络超时、Vue渲染异常）必须自主诊断、自动编写补丁修复并重新测试，直到闭环确认，不得把半成品或报错抛回给用户。
- **静默后台执行**：对大文件打包压缩（如 `ROS-Box.tar`）和 SCP 上传等耗时操作，全自动执行并记录进度，操作完成后向用户展示完整效果截图与数据报告。

## 2. 界面视觉与美化规范 (UI & Aesthetic Standards)
- **品牌名称**：全站全语言统一命名为 `ROS-Box`，副标题为 `ROUTEROS APPLIANCE`。严禁遗留任何 `Open-Box` 字样。
- **设计风格**：采用 **MikroTik 科技深蓝风格**（主色调 `#002d50`、`#004e82`，高光 `#00d2ff`、`#38bdf8`），搭配高质感毛玻璃（Glassmorphism）与半透明晶体层次。
- **LOGO 规范**：使用 3D 水晶微光动力立方体（`logo-cube-v3.svg`），具备动态外层光轨环绕、内核心呼吸等粒子效果，左侧栏 Hero 居中醒目展示（`h-24 w-24`），严禁压缩变形或边缘裁剪。
- **布局平衡**：杜绝大面积突兀留白，拒绝生硬拼凑的附加图框。界面必须精致、克制、平衡、极简。
- **去推广政策**：彻底剔除原项目中所有的商业推广、社交媒体引导卡片、YouTube 视频及无关外链。

## 3. 网络与 RouterOS 架构规范 (Networking & Kernel Rules)
- **RouterOS 专属适配**：仅面向 MikroTik RouterOS Container 环境设计，显示真实设备版本（`RouterOS v7.24.5`）。严禁保留 OpenWrt 或通用 Linux 专有的界面块或未适配依赖。
- **网络栈标准**：
  - 基于 Sing-Box 1.14 内核架构。
  - 启动阶段严格执行 `ip rule` 优先级重排（防止 ROS 7.22+ 默认策略路由拦截）。
  - 支持 TUN 自动网关路由、Smart DNS 0ms 解析、TCP Fast Open (TFO) 全局加速。
- **极致内存控制**：
  - 单进程内存软上限 `GOMEMLIMIT=60MiB`。
  - 剔除 Node.js 开发环境与 npm/yarn 冗余，容器面板与内核空闲运行内存控制在 50~60 MiB。
  - 容器打包必须维持单层高压 Squash 格式（`.tar` <= 265MB, `.tar.gz` <= 103MB）。
