---
layout: post
title: "不只测 github.com：如何为 Clash Verge 选择真正适合 GitHub 的节点"
date: 2026-05-26 17:00:00 +0800
categories: [GitHub, 代理, 效率]
tags: [github, clash-verge, mihomo, proxy, speed-test]
series: [network-proxy]
series_order:
  network-proxy: 3
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

测速分成策略组确认、两轮 delay 测试，以及可选的真实下载测速。

阶段 0 是确认策略组。如果没有指定策略组，先列出可测试策略组并等待确认，不要直接开始测速。

阶段 1 是快速筛选：对确认后的策略组候选节点只测试三个关键目标：

- `github.com`
- `api.github.com`
- `release-assets.githubusercontent.com`

这样可以快速淘汰明显不适合 GitHub 的节点。如果一个节点连 GitHub 网页、API 或 Release 资产下载都不稳定，就没有必要继续完整测试。

阶段 2 是完整 delay 测试：只对阶段 1 三个目标都成功、平均延迟靠前的节点继续测试完整 GitHub 域名组合：

- `github.com`
- `api.github.com`
- `raw.githubusercontent.com`
- `codeload.github.com`
- `objects.githubusercontent.com`
- `release-assets.githubusercontent.com`

最终按稳定性和平均延迟综合判断，而不是只看单个域名的最低延迟。任一关键目标返回 `ERR`、`-1` 或小于等于 `0` 的 delay 值，都应视为失败；排序时排在所有完整成功的节点之后。

需要注意的是，如果使用 Clash Verge / Mihomo 控制接口的 delay 能力，这类测速更适合快速比较节点对目标 URL 的连通性和延迟，不等同于真实大文件下载吞吐测试。真实下载测速应该作为单独阶段，并在用户确认后再执行；未执行真实下载前，不应该给出“下载最快”或“软件更新下载最佳”的结论。

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

执行规则：
1. 默认快速失败。单次控制接口请求超时 1-3 秒；单个 delay 目标超时不要久等。
2. 如果任何阶段命令已经完成，必须立即返回结果，不要继续内部整理或推进未确认阶段。
3. 如果 30 秒内无法完成当前阶段，先返回当前进度和已得到的数据。
4. 未执行真实下载测速前，禁止给出“下载最快”“软件更新下载最佳”“真实下载表现最好”等结论，只能说“基于 delay 的候选”。

阶段 0：发现控制接口和策略组
1. 可以读取 Clash Verge / Mihomo 控制接口。
2. 不要修改规则、订阅或配置文件。
3. 如果我没有指定策略组，先列出可测试策略组，包括：策略组名、类型、当前节点、候选数量，然后停止，等我确认。
4. 如果控制接口不可用，快速返回失败原因和我可以本机运行的脚本。

候选过滤：
1. 跳过明显不是代理节点的条目，例如 DIRECT、REJECT、Auto、策略组、流量提示、到期时间、套餐信息。
2. 不要因为节点名包含“流量倍率”就过滤掉真实节点。
3. 必须保留真实节点名。

阶段 1：快速 delay 测试
1. 只测试确认后的策略组。
2. 测试前记录该策略组当前使用节点。
3. 不切换节点。
4. 对所有候选节点测试：
   - https://github.com
   - https://api.github.com
   - https://release-assets.githubusercontent.com
5. ERR、-1、小于等于 0、超时都记为失败并继续。
6. 阶段 1 完成后立即输出表格，然后继续阶段 2；如果阶段 2 候选为空，立即停止。

阶段 2：完整 delay 测试
1. 只对阶段 1 三个目标都成功、平均延迟最低的前 5-8 个节点测试：
   - https://github.com
   - https://api.github.com
   - https://raw.githubusercontent.com
   - https://codeload.github.com
   - https://objects.githubusercontent.com
   - https://release-assets.githubusercontent.com
2. 输出表格：
   - 真实节点名
   - 是否当前使用节点
   - 各目标 delay
   - 是否有 ERR
   - 平均 delay
   - 推荐排序
3. 排序规则：
   - 所有目标都成功的节点排在前面
   - 任一目标 ERR、-1、小于等于 0、超时的节点排在所有无失败节点之后
   - 平均 delay 只用于无失败节点之间排序
4. 阶段 2 完成后必须立即返回结果。
5. 阶段 2 只能给出网页/API 延迟推荐和下载测速候选，不能给真实下载结论。
6. 然后询问我是否执行真实下载测速。

真实下载测速阶段：
1. 只有在我明确确认后才执行。
2. 会临时切换目标策略组当前节点；切换会影响浏览器、SSH、IDE、CLI 等连接，执行前必须说明。
3. 开始前记录原当前节点；结束后必须恢复原节点，并报告是否恢复成功。
4. 如果无法安全切换和恢复，不要强行执行，给出我可以手动运行的命令。
5. 候选节点取以下并集，去重后最多 6 个：
   - 第二阶段综合排名前 3
   - codeload delay 最低前 3
   - release-assets delay 最低前 3
   - 当前节点
   - codeload、objects 或 release delay 明显偏高但综合靠前的节点
6. 使用 curl 真实下载测速，必须走正在测试的节点：
   - 如果本机没有全局接管流量，使用 `--proxy http://127.0.0.1:<PROXY_PORT>`
   - 使用 `curl -L` 跟随重定向
   - 输出 `url_effective` 确认最终域名
   - 使用 `--max-time 20`
   - 可以使用 `-r 0-10485759` 请求前 10MB，但必须说明 Range 可能被忽略
7. 测试 URL：
   - Release: https://github.com/cli/cli/releases/download/v2.92.0/gh_2.92.0_linux_amd64.tar.gz
   - Source: https://github.com/github/codeql/archive/refs/heads/main.tar.gz

最终输出：
1. 必须标注每个阶段的执行状态：
   - 控制接口读取
   - 第一阶段 delay
   - 第二阶段 delay
   - 真实下载测速
   - 原节点恢复
2. 必须分别说明：
   - 哪个节点最适合 GitHub 网页访问
   - 哪个节点最适合 GitHub Release / codeload 下载
   - 哪个节点真实下载测速表现最好；如果未执行真实下载，必须写“未测试，暂无结论”
   - 哪些节点虽然 github.com 快，但不适合下载
   - 当前正在使用的节点是否推荐继续使用
3. 结果保留真实节点名，不脱敏。
4. 结果是本机使用，不要直接公开分享。
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
