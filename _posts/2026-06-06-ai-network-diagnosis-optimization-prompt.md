---
layout: post
title: "网络诊断与优化 AI Prompt：区分 Wi-Fi、DNS、代理和 TUN 问题"
date: 2026-06-06 17:50:00 +0800
updated: 2026-06-07
categories: [AI, 网络与代理]
tags: [prompt, network, proxy, dns, wifi, tun]
series: [network-proxy]
series_order:
  network-proxy: 4
status:
  label: 当前可用
  verified: 2026-06-28
  environment: AI Agent / Windows、macOS 网络排障
  risk: 只允许执行安全、可逆的诊断和优化；涉及系统网络配置时要先保留 before/after。
---

这是一份面向 AI Agent 的网络诊断与优化提示词模板，重点不是让 Agent 直接“修网络”，而是要求它先区分真实公网链路、系统代理链路、TUN/VPN 链路，再只执行安全、可逆、低风险的优化。

---

网络问题最容易被混在一起判断，网页慢可能是 Wi-Fi 信号差，也可能是 DNS 慢、代理节点慢、TUN 接管默认路由、Fake-IP 冲突，或者只是远端服务本身慢。

如果直接让 AI Agent “帮我优化网络”，它很容易跳过分层诊断，直接改 DNS、关服务、清缓存，最后 before/after 数据混在一起，无法判断到底是哪一层出了问题。

这份提示词的目标，是把网络优化任务拆成五个明确阶段：

- 第一阶段只读诊断，不修改任何网络状态。
- 第二阶段输出诊断报告，把证据、风险和预期收益列清楚。
- 第三阶段等待用户逐项批准。
- 第四阶段只执行已批准的低风险、可逆优化。
- 第五阶段复测并输出 before/after 对比和回滚命令。

## 适合解决什么问题

这份 Prompt 适合下面几类场景：

- 怀疑 Wi-Fi、DNS、代理、VPN 互相影响，但不知道从哪里查起。
- 使用 Clash、Stash、Surge、sing-box、Tailscale、WireGuard 等工具后，访问速度时快时慢。
- 需要 AI Agent 帮忙跑命令诊断网络，但不希望它擅自关闭 VPN、改代理配置或删除网络服务。
- 希望输出 before/after 对比，而不是只给一堆零散命令结果。
- 希望跨 macOS、Windows、Linux 使用，而不是把某个平台命令硬套到所有环境。

它不适合无确认地做高风险网络改动。比如删除网络服务、强行关闭远程连接、改路由表、修改代理配置文件、停止 VPN/TUN 进程，都应该先说明风险并等待用户确认。

## 提示词设计思路

核心原则是：先分层，再优化。

直连链路、系统代理链路、TUN/VPN 链路必须分别判断。否则代理节点慢会被误判为运营商慢，TUN 接管 DNS 会被误判为本机 DNS 配置错误，Wi-Fi 干扰又可能被误判成公网质量差。

第二个原则是：只做低风险、可逆修改。网络环境往往承载远程连接、代理、同步工具、下载任务和局域网访问。Agent 可以建议关闭高流量程序，但不应该擅自停止；可以建议修改代理规则，但不应该直接改配置文件；可以建议刷新 DNS 缓存，但必须先取得用户批准；不应该删除网络配置。

第三个原则是：必须有复测。没有 after 数据，优化就只是猜测。复测至少应该覆盖带宽/延迟、DNS 耗时、默认网关 ping、公网 DNS ping、丢包率、代理/TUN 状态和 Wi-Fi 指标。

## 完整版提示词

```text
目标：诊断并在获得批准后优化当前设备网络环境。先识别操作系统，再使用对应平台命令；不要假设一定是 macOS、Windows 或 Linux。

总体原则：
1. 严格按阶段执行：只读诊断 -> 诊断报告 -> 等待批准 -> 执行已批准优化 -> before/after 复测。
2. 第一阶段只能检查，不能修改任何网络设置、DNS、MTU、Proxy、VPN、TUN、profile、服务或后台程序。
3. 所有修改必须安全、可逆、低风险。需要管理员权限、sudo、UAC，或可能影响 VPN、代理、远程连接、当前会话时，必须先说明风险并等待确认。
4. 不删除网络配置；不自动关闭、切换、重连或修改代理、VPN、TUN；不 kill、throttle 或关闭下载器、网盘、同步工具、浏览器或视频应用，除非用户明确批准。
5. 不把代理造成的访问慢误判为 Wi-Fi、DNS 或运营商链路问题；必须分开判断直连链路、系统代理链路、TUN/VPN 链路。
6. 优化优先级是：稳定性 > 延迟 > 下载速度；不得为了速度牺牲安全性或必要功能。

第一阶段：只读检查
1. 先识别当前操作系统，再选择对应平台命令。
2. 先跑低流量 before 基准：
   - DNS 查询耗时
   - 到默认网关 ping
   - 到公网 DNS ping
   - 丢包率
3. 如需执行 speedtest、networkQuality 或任何大量占用网络流量的测试，必须先说明预计消耗和可获得的证据，并询问用户是否同意。
4. 如遇到需要更高权限的只读命令，必须先说明用途和没有该证据时报告会有哪些限制，再请求批准。
5. 识别真实公网链路：
   - 默认路由
   - 活跃网络接口
   - 网关
   - DNS
   - MTU
   - 网络服务/接口优先级
6. 检查代理/VPN/TUN：
   - 系统代理
   - WinHTTP/浏览器/环境变量代理
   - HTTP/SOCKS/mixed 代理端口
   - TUN/TAP/Wintun/utun/虚拟网卡
   - 默认路由是否被虚拟接口接管
   - DNS 是否被代理或 VPN 接管
7. 检查 Wi-Fi 质量：
   - SSID
   - 频段
   - 信道
   - 信道带宽
   - RSSI/信号强度
   - 噪声或平台可用替代指标
   - Tx/Rx Rate
   - 周边网络和同频干扰
   - 当前 AP 负载或可用替代指标
8. 检查 DNS/mDNS：
   - 当前 DNS 服务器
   - DNS 查询耗时，对比多个候选 DNS
   - DNS 缓存状态
   - mDNS/Bonjour/Avahi 状态
   - 是否存在 Fake-IP、DoH、DoT、DNS hijack、fallback DNS
9. 检查 MTU：
   - 当前接口 MTU
   - DF ping 或平台等价方式探测路径 MTU
   - 判断 MTU 问题是在本机接口还是上游链路
10. 找出高流量或可能接管路由的后台进程，但只报告，不关闭：
   - VPN
   - Tailscale / ZeroTier / WireGuard / OpenVPN
   - Clash / Stash / Shadowrocket / Surge / sing-box / v2ray / xray
   - iCloud / OneDrive / Dropbox / 百度网盘 / 阿里云盘
   - 下载器 / BT 客户端 / 游戏加速器
   - 浏览器或视频应用

代理专项要求：
1. 分别判断三类链路：
   - 直连公网链路：绕过代理测试默认网关、公网 DNS、常见站点。
   - 系统代理链路：走 HTTP/SOCKS/mixed 代理测试访问延迟。
   - TUN/VPN 链路：检查默认路由、策略路由和 DNS 是否经虚拟接口。
2. 对代理做对照测试：
   - 记录当前代理状态。
   - 测试直连 DNS 延迟。
   - 测试系统代理开启时访问延迟。
   - 如可安全执行，再测试临时绕过代理访问同一目标。
3. 如果发现 Clash/Stash/Shadowrocket/Surge/sing-box 等代理工具：
   - 检查系统代理端口、mixed/http/socks 端口。
   - 检查是否启用 TUN。
   - 检查是否启用 Fake-IP、redir-host、DNS hijack、DoH/DoT、fallback DNS。
   - 检查 bypass 列表是否包含 localhost、127.0.0.1、192.168.*、10.*、172.16-31.*。
   - 检查国内站点、国外站点、局域网地址、DNS 查询分别命中 DIRECT / PROXY / REJECT / TUN 哪条路径。
   - 检查代理节点延迟、丢包、失败率、是否频繁切换。
4. 如果代理开启和关闭差异明显，必须判断原因：
   - DNS 慢
   - 节点慢
   - 规则错误
   - TUN 接管
   - Fake-IP 冲突
   - fallback DNS 慢或污染
   - 远端网站本身慢
5. 未经明确授权，不直接修改代理配置文件；只给建议和可回滚命令。

第二阶段：诊断报告
请用简体中文输出报告，格式如下：

1. 检查摘要
   - 当前是否有明显瓶颈
   - 主要问题排名
   - 是否建议优化

2. 发现的问题
   每个问题必须包含：
   - 问题描述
   - 证据，例如 latency、DNS query time、packet loss、Wi-Fi signal、VPN route
   - 可能原因
   - 对网速的可能影响：下载速度、上传速度、网页反应、延迟或稳定性
   - 预期改善幅度
   - 风险等级：低 / 中 / 高
   - 是否值得处理

3. 不建议动的地方
   例如：
   - MTU 正常就不要改
   - mDNS 没有证据拖慢上网就不要优化
   - network profiles / locations / services 不确定用途就不要删或禁用
   - DNS 若被 VPN 接管，不要盲目改
   - 代理、VPN、TUN 必须保持可用

4. 建议优化方案
   按照“最可能有效、最低风险”排序。每个方案必须包含：
   - 要做什么
   - 为什么值得做
   - 可能风险
   - 如何还原
   - 预期改善的是下载速度、网页反应、延迟还是稳定性
   - 是否需要管理员权限，或是否会影响 VPN、代理、远程连接、当前会话

第三阶段：等待用户批准
在执行任何优化前，必须明确问用户：

“你是否批准执行以下优化项目？”

并逐项列出每一项将会执行的操作。

未经用户批准，不得执行：
- 修改 DNS
- 修改 MTU
- 删除或禁用 network locations / profiles / services
- 关闭、kill 或 throttle 背景程序
- 重启网络服务
- 关闭、切换、重连或修改 VPN、代理、TUN
- flush DNS / mDNS cache
- 更改 Wi-Fi 或路由器设定
- 执行 speedtest、networkQuality 或其他高流量测试

第四阶段：执行已批准的优化
只执行用户批准的项目。
每个改动前，请先用一句话说明即将做什么。
每次只做一类改动，做完后立即检查结果。
不得顺手清理无关设定。
必须记录所有已执行修改和对应回滚命令。

可建议的优化项：
1. 将真实使用的 Wi-Fi 或以太网接口排到网络服务/接口优先级第一位。
2. 禁用明显无用的伪网络服务或旧网络服务，但不要删除配置；不确定就只提示；确认无用且用户批准后才禁用。
3. 根据实测 DNS 延迟设置更快的 DNS。
4. 刷新 DNS 缓存。
5. 刷新 mDNS/Bonjour/Avahi 缓存或重启对应服务。
6. 对明显占用带宽的后台程序，只提示用户关闭；不要擅自停止。
7. 对代理/VPN/TUN：
   - 如果代理影响测试，提示用户临时切换到 DIRECT 或暂停代理。
   - 如果 TUN/VPN 接管默认路由，先说明影响，不要强行关闭。
   - 如果规则或 DNS 模式明显不合理，只给修改建议，不直接改配置。
8. 对 MTU：
   - 只有确认本机接口 MTU 设置错误时才建议修改。
   - 如果路径 MTU 限制来自上游链路，只记录并建议在路由器/运营商侧处理。

第五阶段：复测
优化后重新测试：
   - DNS 查询耗时
   - 默认网关 ping
   - 公网 DNS ping
   - 丢包率
   - Wi-Fi 状态
   - 默认路由
   - DNS 配置
   - 代理/VPN/TUN 状态
   - 如用户批准，执行 speedtest 或 networkQuality

对比 before/after：
   - 下行
   - 上行
   - 空闲延迟
   - 加载延迟
   - 丢包
   - DNS 耗时
   - 默认路由
   - DNS 配置
   - 代理/VPN/TUN 状态
   - Wi-Fi 指标

最后输出：
   - 当前真实链路结论
   - 系统代理链路结论
   - TUN/VPN 链路结论
   - Wi-Fi 质量结论
   - 3 个主要问题
   - 已修复项
   - 没有明显改善的项目
   - 未修复但建议手动处理项
   - 是否建议保留改动
   - 是否有需要还原的项目
   - 所有已执行修改的回滚命令
   - 下一步建议

平台命令参考：
1. macOS：
   - `networkQuality`
   - `scutil --nwi`
   - `route get default`
   - `scutil --dns`
   - `scutil --proxy`
   - `networksetup`
   - `ifconfig`
   - `netstat -rn`
   - `lsof -i`
   - `airport` 或 `wdutil`
2. Windows：
   - `route print`
   - `Get-NetIPConfiguration`
   - `Get-DnsClientServerAddress`
   - `Get-NetIPInterface`
   - `Get-NetIPAddress`
   - `netsh wlan show interfaces`
   - `netsh wlan show networks mode=bssid`
   - `netsh winhttp show proxy`
   - 当前用户代理注册表
   - `Get-NetTCPConnection`
   - `Get-Process`
   - `Resolve-DnsName`
   - `Test-Connection` / `ping`
3. Linux：
   - `ip route`
   - `ip addr`
   - `resolvectl`
   - `nmcli`
   - `iw`
   - `ss`
   - `dig`
   - `ping`
   - `tracepath`
   - `systemctl status avahi-daemon`
```

## 使用建议

如果要把这份提示词交给 AI Agent 使用，建议先补充三个上下文：

- 当前设备系统：macOS、Windows 或 Linux，如果不确定就让 Agent 自行识别。
- 当前是否依赖远程连接、VPN、代理或 TUN；如果依赖，明确禁止自动关闭。
- 你能接受的操作范围，例如“只读诊断”“允许刷新 DNS 缓存”“允许修改 DNS 但必须给回滚命令”。

更稳妥的使用方式，是先让 Agent 只执行诊断阶段，输出 before 数据和判断依据；确认没有误判代理、VPN、TUN 后，再允许它执行低风险优化。

## 输出验收标准

一次合格的执行结果，至少应该包含这些内容：

- 真实公网链路、代理链路、TUN/VPN 链路分别是什么状态。
- Wi-Fi 质量是否足够好，是否存在明显信号、信道或干扰问题。
- DNS 查询耗时是否异常，候选 DNS 是否经过实测对比。
- before/after 数据是否可比较。
- 执行过哪些修改，以及每项修改如何回滚。
- 哪些问题没有自动处理，需要用户手动关闭程序、调整代理规则或处理路由器/运营商侧问题。

这类任务的关键不是“自动修复越多越好”，而是让 Agent 保持边界：把网络路径拆清楚，把风险说清楚，把证据留下来。
