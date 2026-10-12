---
name: rosbox-upstream-sync
description: >-
  Use this skill for tracking upstream Open-Box releases, sing-box core updates, GeoIP/GeoSite rule updates, and automatically applying ROS-Box branding and RouterOS compatibility patches.
---

# ROS-Box Upstream Sync & Rule Evolution Skill

## 职责定位
负责追踪官方 Open-Box 以及底层 Sing-Box、GeoIP/GeoSite 的更新动态。在同步新功能的同时，全自动应用 ROS-Box 规范（去广告、注入 3D 动力立方体、注入 RouterOS 容器兼容层），确保既能同步最新功能，又保持纯净稳定。

## 自动化同步流程
1. **上游探测 (Upstream Probing)**：
   - 检查 GitHub 上游版本发布（Release tags / commit hash）。
   - 提取新版中的分流规则模型、DNS 增强特性与协议支持。
2. **自动化规范化补丁 (Rebrand & Patch)**：
   - 将所有界面的品牌文案自动替换为 `ROS-Box`。
   - 保留 3D 立体动态立方体 LOGO（`logo-cube-v3.svg`）与 Hero 卡片布局。
   - 剔除上游新增的推广广告、外部社交链接。
   - 固化 Vue 3 卸载防护补丁与 RouterOS 专属硬件状态卡片。
3. **内核规则库更新**：
   - 自动拉取最新的 GeoSite 与 GeoIP 数据库。
   - 验证规则编译完整性后注入，无需人工干预。
