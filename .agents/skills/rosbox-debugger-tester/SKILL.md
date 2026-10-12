---
name: rosbox-debugger-tester
description: >-
  Use this skill for automated testing, Playwright headless browser E2E verification, console error monitoring, kernel log debugging, container lifecycle diagnostics, and packaging verification.
---

# ROS-Box Debugger & Test Specialist Skill

## 职责定位
专门负责端到端自动化测试、浏览器控制台错误拦截、无头渲染截屏比对、内核日志崩溃诊断与镜像打包校验。

## 调试手段与验证流程
1. **自动化端到端 (E2E) 测试**：
   - 使用 Playwright / 无头浏览器直接访问容器 `http://10.0.0.11:2026/`。
   - 监听浏览器 Console，严防任何 `Uncaught TypeError` 或渲染警报。
   - 自动模拟用户点击侧边栏菜单切换（概览、代理、连接、设置各子选项卡），验证视图平滑渲染。
   - 截取高清屏幕截图，作为用户交付与视觉验收的客观依据。
2. **内核与系统日志追踪**：
   - 监控 `/var/log` 与内核 stdout，重点排查 sing-box 的 `FATAL` 级别崩溃信息。
   - 通过 SSH 探测 RouterOS 容器状态 (`/container/print`)，排查死锁与反复重启。
3. **镜像完整性与体积核验**：
   - 自动运行 `build_ultra_compact_rosbox.py` 构建镜像后，校验 `manifest.json`、`layer.tar` 与 SHA256 哈希。
   - 监测 `.tar` 镜像体积不超过 265MB，`.tar.gz` 压缩包不超过 103MB。
   - 确保通过 SCP 自动传输后，RouterOS 宿主磁盘上的大小与修改时间与本地严格匹配。
