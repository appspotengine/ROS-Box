---
name: rosbox-ux-optimizer
description: >-
  Use this skill for user experience optimization, smooth Vue router navigation without crashes, multi-language localization consistency, clean ad-free flows, and version checking.
---

# ROS-Box User Experience (UX) Optimizer Skill

## 职责定位
专门负责用户交互体验、操作流转顺畅度、文案统一性、去推广净化以及版本升级状态感知。

## 优化要点与执行指南
1. **路由与组件无缝切换**：
   - 守护 Vue 3 组件卸载过程：在 `index-D5a7ItBd.js` 的 `Ue` 卸载函数中添加组件实例空值防护 (`if (!d) return;`)，彻底杜绝切换菜单时 `Cannot destructure property 'bum' of 'd'` 导致的白屏与报错。
   - Hash 路由深度适配：确保所有内部跳转均通过原生路由总线无刷新完成。
2. **纯粹体验与去推广**：
   - 彻底删除原项目所有的 YouTube 教程推荐、作者推广社交卡片及外部广告引流。
   - 保留与 ROS-Box 运行密切相关的配置选项，减少对用户的干扰。
3. **版本状态与操作感知**：
   - 真实读取 MikroTik RouterOS 宿主系统版本与状态（如 `RouterOS v7.24.5 (stable)`）。
   - 提供直观醒目的“检查更新 / 升级”快捷入口，状态反馈明确清晰。
4. **统一命名与多语言一致性**：
   - 全语言（简中、繁中、英文）中统一规范为 `ROS-Box`。
   - 浏览器标签页标题格式统一为 `ROS-Box | <模块名>`。
