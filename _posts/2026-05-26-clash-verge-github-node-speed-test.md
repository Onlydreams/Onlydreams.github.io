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

第一阶段是快速筛选：先确认要测试的策略组，再对该组里的候选节点只测试两个关键目标：

- `github.com`
- `release-assets.githubusercontent.com`

这样可以快速淘汰明显不适合 GitHub 的节点。如果一个节点连 GitHub 网页或 Release 资产下载都不稳定，就没有必要继续完整测试。

第二阶段是完整测试：只对第一阶段两个目标都成功、平均延迟靠前的节点继续测试完整 GitHub 域名组合：

- `github.com`
- `api.github.com`
- `raw.githubusercontent.com`
- `codeload.github.com`
- `objects.githubusercontent.com`
- `release-assets.githubusercontent.com`

最终按稳定性和平均延迟综合判断，而不是只看单个域名的最低延迟。任一关键目标返回 `ERR` 的节点，排序时应排在所有完整成功的节点之后。

需要注意的是，如果使用 Clash Verge / Mihomo 控制接口的 delay 能力，这类测速更适合快速比较节点对目标 URL 的连通性和延迟，不等同于真实大文件下载吞吐测试。如果要进一步验证下载吞吐，只建议对综合排序前 2-3 个候选节点追加真实下载测速，避免浪费太多流量。

## 真实下载测速

前两阶段主要测试连通性和延迟。如果要进一步验证下载吞吐，可以对综合排序前 2-3 个节点做真实下载测速。

推荐使用 GitHub 官方相关 URL：

- Release 资产：`https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz`
- 源码包：`https://github.com/github/codeql/archive/refs/heads/main.tar.gz`

这类测试会产生真实网络流量。使用 `curl -L -o /dev/null` 可以只输出统计信息，不会在当前目录留下需要清理的临时文件。

如果想减少流量，优先限制测试时间。`-r` 范围请求可以尝试只请求前 10MB，但部分下载端可能忽略 Range，不能把它当作硬性流量上限。

```bash
curl -L --max-time 20 -o /dev/null -w 'time=%{time_total}s speed=%{speed_download}B/s url=%{url_effective}\n' \
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
5. 第一阶段对目标策略组里的所有候选节点快速测试：
   - https://github.com
   - https://release-assets.githubusercontent.com
6. 第一阶段要快速失败：
   - 单个目标超时不要等太久
   - 如果节点返回 ERR 或明显超时，记录结果并继续下一个节点
   - 不要长时间卡住不反馈
7. 第二阶段只对第一阶段两个目标都成功、平均延迟最低的前 5-8 个节点做完整测试，目标包括：
   - https://github.com
   - https://api.github.com
   - https://raw.githubusercontent.com
   - https://codeload.github.com
   - https://objects.githubusercontent.com
   - https://release-assets.githubusercontent.com
8. 输出结果表格，必须保留真实节点名，方便我直接在 Clash Verge 里切换节点：
   - 真实节点名
   - 是否为当前使用节点
   - 各目标延迟
   - 是否有 ERR
   - 平均延迟
   - 推荐排序
9. 排序规则：
   - 所有目标都成功的节点排在前面
   - 任一目标 ERR 的节点排在所有无 ERR 节点之后
   - 平均延迟只用于无 ERR 节点之间的排序
10. 如果需要进一步验证真实下载速度，只对综合排序前 2-3 个节点做真实下载测速：
   - 真实下载测速可能需要临时切换目标策略组的当前节点；开始前先记录原当前节点，测试结束后必须恢复原节点，并说明是否恢复成功
   - 如果无法安全切换并恢复，请不要强行执行，改为说明限制并给出我可以手动运行的命令
   - Release 资产测速使用 GitHub 官方 CLI 的 release 文件：
     https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz
   - 源码包测速使用 GitHub 官方仓库源码包：
     https://github.com/github/codeql/archive/refs/heads/main.tar.gz
   - 下载测速需要产生真实网络流量；使用 `curl -L -o /dev/null` 输出统计信息即可，不会在当前目录留下需要清理的临时文件
   - 为避免消耗太多流量，优先使用 `--max-time 20` 限制测试时间；可以尝试使用 `-r 0-10485759` 只请求前 10MB，但 Range 可能被下载端忽略，不能把它当作硬性流量上限
11. 最终结论要说明：
   - 哪个节点最适合 GitHub 网页访问
   - 哪个节点最适合 GitHub 软件更新下载
   - 哪个节点真实下载测速表现最好
   - 哪些节点虽然 github.com 快，但不适合下载
   - 当前正在使用的节点是否推荐继续使用
12. 如果当前 AI Agent 运行在沙箱里，无法直接访问本机 Clash Verge / Mihomo 控制接口，请告诉我需要授权，或者给出我可以在本机运行的脚本。
13. 这是本机使用的测速结果，不需要适合公开发布；不要为了脱敏隐藏节点名，否则我无法判断应该切换到哪个节点。结果会包含真实节点名，不要直接公开分享。
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
