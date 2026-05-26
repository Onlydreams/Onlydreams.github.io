---
layout: post
title: "不只测 github.com：如何为 Clash Verge 选择真正适合 GitHub 的节点"
date: 2026-05-26 17:00:00 +0800
categories: [GitHub, 代理, 效率]
tags: [github, clash-verge, mihomo, proxy, speed-test]
---

很多人测试代理节点访问 GitHub 的速度时，只会测 `github.com`。这个方法不够准确。

---

GitHub 的网页访问、源码下载、Release 软件更新、Raw 文件读取，背后会涉及多个不同域名。一个节点访问 `github.com` 很快，不代表它下载 GitHub Release 资产也快；反过来，某些节点打开网页正常，但下载更新包时可能会卡在其他 GitHub 资源域名上。

这次测速的目标很明确：从 Clash Verge 当前配置的候选节点里，找出同时适合 GitHub 网页访问和 GitHub 软件更新下载的节点。

## 测速目标

这次不只测试 `github.com`，而是覆盖 GitHub 常见访问链路：

| 目标 | 用途 |
|---|---|
| `github.com` | GitHub 网页、仓库页面 |
| `api.github.com` | GitHub API、CLI、插件、自动化工具 |
| `raw.githubusercontent.com` | Raw 文件读取、脚本安装、配置拉取 |
| `codeload.github.com` | 仓库 zip/tar 下载 |
| `objects.githubusercontent.com` | Git 对象、部分资源下载 |
| `release-assets.githubusercontent.com` | Release 软件包、更新包下载 |

其中最关键的是：

- `github.com`：决定网页体验
- `release-assets.githubusercontent.com`：决定很多软件从 GitHub 下载更新包的体验
- `codeload.github.com` / `objects.githubusercontent.com`：决定源码包、依赖包、GitHub 资源下载体验

所以只测 `github.com` 是不够的。

## 测速思路

测速先分两阶段进行。

第一阶段是快速筛选：先确认要测试的策略组，再对该组里的候选节点只测试三个关键目标：

- `github.com`
- `api.github.com`
- `release-assets.githubusercontent.com`

这样可以快速淘汰明显不适合 GitHub 的节点。如果一个节点连 GitHub 网页、API 或 Release 资产下载都不稳定，就没有必要继续完整测试。

第二阶段是完整测试：只对第一阶段三个目标都成功、平均延迟靠前的节点继续测试完整 GitHub 域名组合：

- `github.com`
- `api.github.com`
- `raw.githubusercontent.com`
- `codeload.github.com`
- `objects.githubusercontent.com`
- `release-assets.githubusercontent.com`

最终按稳定性和平均延迟综合判断，而不是只看单个域名的最低延迟。任一关键目标返回 `ERR`、`-1` 或小于等于 `0` 的 delay 值，都应视为失败；排序时排在所有完整成功的节点之后。

需要注意的是，如果使用 Clash Verge / Mihomo 控制接口的 delay 能力，这类测速更适合快速比较节点对目标 URL 的连通性和延迟，不等同于真实大文件下载吞吐测试。如果要进一步验证下载吞吐，不要只选平均延迟最低的节点，建议取综合排名前 3 和下载相关目标延迟最低前 3 的并集，再做真实下载测速，避免因为 delay 和吞吐脱节而选错节点。

## 真实下载测速

前两阶段主要测试连通性和延迟。如果要进一步验证下载吞吐，可以取综合排名前 3 和下载相关目标延迟最低前 3 的并集，再做真实下载测速。

推荐使用 GitHub 官方相关 URL：

- Release 资产：`https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz`
- 源码包：`https://github.com/github/codeql/archive/refs/heads/main.tar.gz`

这两个都是 GitHub 官方入口地址。使用 `curl -L` 时会跟随重定向到实际下载域名：Release 资产通常会落到 `release-assets.githubusercontent.com`，源码包通常会落到 `codeload.github.com`。测速时应输出 `url_effective`，确认最终访问的真实下载域名。

这类测试会产生真实网络流量。使用 `curl -L -o /dev/null` 可以只输出统计信息，不会在当前目录留下需要清理的临时文件。真实下载测速时要确保 `curl` 流量经过正在测试的节点；如果本机没有全局接管，需要显式使用 Clash Verge / Mihomo 的 HTTP 或 mixed 代理端口。

如果想减少流量，优先限制测试时间。`-r` 范围请求可以尝试只请求前 10MB，但部分下载端可能忽略 Range，不能把它当作硬性流量上限。

```bash
curl -L --max-time 20 -o /dev/null -w 'time=%{time_total}s speed=%{speed_download}B/s url=%{url_effective}\n' \
  'https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz'
```

如果需要显式指定本地代理端口，可以使用类似命令：

```bash
curl -L --proxy http://127.0.0.1:<PROXY_PORT> --max-time 20 -o /dev/null -w 'time=%{time_total}s speed=%{speed_download}B/s url=%{url_effective}\n' \
  'https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz'
```

## 给 AI Agent 的提示词

如果希望让 AI Agent 帮你完成类似测速，可以使用下面这段提示词。

```text
请帮我测试 Clash Verge / Mihomo 中指定策略组或经我确认的策略组里的候选节点，目标是找出最适合访问 GitHub 的节点。

要求：
1. 不要只测试 github.com。
2. 如果我没有指定策略组，先列出可测试的策略组并让我确认；如果我已经指定策略组，只测试该策略组。
3. 测试前先记录当前策略组正在使用的节点，并在结果表里标注“当前使用”。
4. 可以读取 Clash Verge / Mihomo 的控制接口并使用 delay 测试。不要修改规则、订阅或配置文件；除真实下载测速需要外，不要切换当前节点。
5. 跳过明显不是代理节点的条目，例如流量提示、到期时间、套餐信息、DIRECT、REJECT、Auto 等非标准代理项。
6. 第一阶段对目标策略组里的所有候选节点快速测试：
   - https://github.com
   - https://api.github.com
   - https://release-assets.githubusercontent.com
7. 第一阶段要快速失败：
   - 单个目标超时不要等太久
   - 如果节点返回 ERR、-1、小于等于 0 的 delay 值，或明显超时，记录结果并继续下一个节点
   - 不要长时间卡住不反馈
8. 第二阶段只对第一阶段三个目标都成功、平均延迟最低的前 5-8 个节点做完整测试，目标包括：
   - https://github.com
   - https://api.github.com
   - https://raw.githubusercontent.com
   - https://codeload.github.com
   - https://objects.githubusercontent.com
   - https://release-assets.githubusercontent.com
9. 输出结果表格，必须保留真实节点名，方便我直接在 Clash Verge 里切换节点：
   - 真实节点名
   - 是否为当前使用节点
   - 各目标延迟
   - 是否有 ERR
   - 平均延迟
   - 推荐排序
10. 排序规则：
   - 所有目标都成功的节点排在前面
   - 任一目标 ERR、-1、小于等于 0 的 delay 值或明显超时的节点排在所有无失败节点之后
   - 平均延迟只用于无 ERR 节点之间的排序
   - 第二阶段结果中 codeload、objects 或 release 延迟明显偏高的节点，即使综合平均排名靠前，也要纳入真实下载测速验证
11. 如果需要进一步验证真实下载速度，取综合排名前 3 和下载相关目标延迟最低前 3 的并集做真实下载测速：
   - 真实下载测速可能需要临时切换目标策略组的当前节点；开始前先记录原当前节点，测试结束后必须恢复原节点，并说明是否恢复成功
   - 临时切换节点会即时影响正在走该策略组的浏览器、SSH、IDE、CLI 等连接；切换前先说明可能出现短暂断连
   - 如果无法安全切换并恢复，请不要强行执行，改为说明限制并给出我可以手动运行的命令
   - Release 资产测速使用 GitHub 官方 CLI 的 release 文件：
     https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz
   - 源码包测速使用 GitHub 官方仓库源码包：
     https://github.com/github/codeql/archive/refs/heads/main.tar.gz
   - 这两个 URL 是 GitHub 官方入口地址；测速时必须使用 `curl -L` 跟随重定向，并输出 `url_effective` 确认最终下载域名。Release 资产通常会跳转到 `release-assets.githubusercontent.com`，源码包通常会跳转到 `codeload.github.com`
   - 下载测速需要产生真实网络流量；使用 `curl -L -o /dev/null` 输出统计信息即可，不会在当前目录留下需要清理的临时文件
   - 必须确保 `curl` 走正在测试的节点；如果本机没有全局接管流量，需要使用 `--proxy http://127.0.0.1:<PROXY_PORT>` 指定 Clash Verge / Mihomo 的 HTTP 或 mixed 代理端口
   - 为避免消耗太多流量，优先使用 `--max-time 20` 限制测试时间；可以尝试使用 `-r 0-10485759` 只请求前 10MB，但 Range 可能被下载端忽略，不能把它当作硬性流量上限
12. 最终结论要说明：
   - 哪个节点最适合 GitHub 网页访问
   - 哪个节点最适合 GitHub 软件更新下载
   - 哪个节点真实下载测速表现最好
   - 哪些节点虽然 github.com 快，但不适合下载
   - 当前正在使用的节点是否推荐继续使用
13. 如果当前 AI Agent 运行在沙箱里，无法直接访问本机 Clash Verge / Mihomo 控制接口，请告诉我需要授权，或者给出我可以在本机运行的脚本。
14. 这是本机使用的测速结果，不需要适合公开发布；不要为了脱敏隐藏节点名，否则我无法判断应该切换到哪个节点。结果会包含真实节点名，不要直接公开分享。
```

## 结果解读方式

测速时不要只看平均值，还要看有没有 `ERR`。

| 情况 | 判断 |
|---|---|
| `github.com` 很快，但 `release-assets` 报错 | 不适合 GitHub 软件更新 |
| `release-assets` 很快，但 `raw` / `codeload` 报错 | 可能下载 Release 快，但拉源码或脚本不稳定 |
| 六个目标都能返回，平均延迟较低 | 更适合作为 GitHub 通用节点 |
| 某个节点成本低但多个 GitHub 域名 ERR | 便宜但不可靠，不建议用于 GitHub |
| 单项极快但多项失败 | 不如稳定节点 |
| delay 排名靠前，但真实下载速度慢 | 浏览可能可用，下载场景不优先 |
| delay 一般，但真实下载速度稳定 | 可以作为下载 Release 或源码包的候选 |

真正适合 GitHub 的节点，不一定是 `github.com` 延迟最低的节点，而是 GitHub 相关域名整体稳定、下载域名不掉链子的节点。

如果 delay 结果和真实下载测速冲突，要按使用场景判断：日常浏览优先看 `github.com` / `api.github.com` 的延迟；下载软件、更新工具、拉源码包时，优先看真实下载测速。

## 建议

如果目标是日常浏览 GitHub，可以重点看：

- `github.com`
- `api.github.com`

如果目标是从 GitHub 下载软件、更新工具、安装 CLI、拉取 Release 包，则必须重点看：

- `release-assets.githubusercontent.com`
- `objects.githubusercontent.com`
- `codeload.github.com`
- `raw.githubusercontent.com`

最终推荐选择所有关键目标都稳定返回、平均延迟较低的节点，而不是只选 `github.com` 延迟最低的节点。
