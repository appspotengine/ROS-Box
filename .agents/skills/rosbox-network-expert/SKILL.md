---
name: rosbox-network-expert
description: >-
  Use this skill for RouterOS container networking, sing-box core configuration, TUN mode policy routing, ip rule priority fixing, Smart DNS, TFO acceleration, and traffic rules.
---

# ROS-Box Network & Kernel Specialist Skill

## 职责定位
专门负责 MikroTik RouterOS Container 环境下的网络底层打通、内核（Sing-Box）配置调优、路由策略分流与低延迟加速。

## 关键技术栈与实施规范
1. **RouterOS Container 网络特性**：
   - 依赖 RouterOS 提供的 `veth` 虚拟以太网接口与 Bridge 桥接通讯。
   - 必须在容器启动时执行 `ip rule` 优先级重排逻辑，规避 RouterOS 7.22+ 预占的高优先级策略规则（如 pref 1/2/3），保证 Sing-Box 的 TUN 策略路由生效：
     ```bash
     while ip rule show | grep -Eq '^1:\s+from all lookup local'; do ip rule del pref 1 2>/dev/null || break; done
     while ip rule show | grep -Eq '^2:\s+from all lookup main'; do ip rule del pref 2 2>/dev/null || break; done
     while ip rule show | grep -Eq '^3:\s+from all lookup default'; do ip rule del pref 3 2>/dev/null || break; done
     ```
2. **内核架构与加速**：
   - 基于 Sing-Box 1.14 高性能内核。
   - 开启 TCP Fast Open (`tcp_fast_open: true`) 全局握手加速，降低首次建立连接延迟。
   - 针对国内流量启用纯内存 FakeIP / Direct 直连绕过，实现 0ms 智能 DNS 响应。
3. **内存控制与防爆**：
   - 环境变量注入 `GOMEMLIMIT=60MiB`，强制 Go runtime 在内存吃紧时触发垃圾回收。
   - 保证容器在低配硬件（如 MikroTik hEX / RB5009 等单核或低内存设备）上稳定运行。
