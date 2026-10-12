---
name: rosbox-watchdog-daemon
description: >-
  Use this skill for autonomous health monitoring, daemon watchdog, memory leak detection, Smart DNS latency probing, and auto-recovery of the RouterOS ROS-Box container.
---

# ROS-Box Watchdog & Health Daemon Skill

## 职责定位
负责无人值守场景下的容器健康巡检、内存监控、网络延迟探测与故障自愈，保障系统 7x24 小时高可用。

## 自动化守护机制
1. **健康心跳监测**：
   - 周期性对 `http://10.0.0.11:2026/` 进行探活，检查 HTTP 状态码。
   - 探测 DNS 响应延迟，确保 Smart DNS 处于 0~2ms 极速响应区间。
2. **内存阈值与泄露预警**：
   - 实时读取 RouterOS 容器内存（`/container/print`）。
   - 监控内部 Node 面板与 sing-box 进程总内存；若超过 80MiB 预警线，自动触发软 GC 或重启，确保不触发 OOM。
3. **故障自愈流水线 (Self-Healing)**：
   - 若检测到服务未响应或内核崩溃（FATAL），自动通过 SSH 触发容器快速重启：
     ```routeros
     /container/stop [find name="open-box-ros-amd64"]
     :delay 2s
     /container/start [find name="open-box-ros-amd64"]
     ```
   - 记录自愈日志，全程自主完成，无需用户唤醒。
