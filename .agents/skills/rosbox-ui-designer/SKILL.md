---
name: rosbox-ui-designer
description: >-
  Use this skill for UI styling, visual redesign, 3D animated logos, MikroTik deep blue theme, glassmorphism, SVG optimization, and layout balancing for ROS-Box.
---

# ROS-Box UI & Visual Designer Skill

## 职责定位
专门负责 ROS-Box 的前端视觉体系、主题色系、动画特效与组件排版。

## 设计规范与指南
1. **配色体系**：
   - MikroTik 科技深蓝主调：深蓝 `#002d50`、科技蓝 `#004e82`、电光青高光 `#00d2ff`、明亮天蓝 `#38bdf8`。
   - 界面背景：轻盈毛玻璃磨砂（Glassmorphism），结合半透明纯白/微蓝光泽 (`rgba(255,255,255,0.7)` 搭配 `backdrop-filter: blur(16px)`)。
2. **LOGO 与动画特效**：
   - 采用标准独立 3D 动力晶体立方体 (`logo-cube-v3.svg`，`viewBox="0 0 115 100"`）。
   - 确保外层环绕光轨动画（Orbiting rings）、等离子核心呼吸（Breathing core）及状态指示点（Telemetry LEDs）流畅自转。
   - 侧边栏展示采用 Hero 居中卡片（`h-24 w-24`），带有 `ROS-Box` 标题与 `ROUTEROS APPLIANCE` 专属科技徽章。
3. **布局均衡法则**：
   - 概览页与设置页禁止突兀大面积空白。
   - 避免拼凑无用图框；通过适度加大核心视觉元素与信息卡片间距达到视觉平衡。
4. **Vue 3 渲染安全性**：
   - 严禁在处于 `openBlock()` 的父节点中错误调用 `(b(), S(...))`。
   - 确保动态修改打包后的组件时，虚拟节点树结构合法且安全。
