# 文章状态信息块设计

## 目标

给技术配置、排障和工具教程类文章增加一个轻量的状态信息块，让读者在执行命令或参考方案前先判断：这篇文章当前是否仍适用、最后验证情况、适用环境和潜在风险。

## 范围

本次包含：

- 在文章页标题和正文之间渲染状态信息块。
- 使用文章 front matter 中的 `status` 对象维护状态信息。
- 给所有历史文章初始化状态字段。
- 增加独立 include，避免把状态块逻辑堆进 `_layouts/post.html`。
- 增加样式和测试。

本次不包含：

- 自动检测文章是否过期。
- 自动扫描外部工具版本或联网验证文章内容。
- 在首页、专题页、分类页、标签页展示状态。
- 把 `status.verified` 写入 SEO `dateModified`。
- 对历史文章正文做实质更新。

## 内容模型

文章可选增加 `status` front matter：

```yaml
status:
  label: 当前可用
  verified: 2026-06-28
  environment: macOS 15 / Git 2.x / Clash Verge
  risk: 会修改本机代理或 Git 配置，执行前建议备份原配置。
```

字段含义：

- `status.label`：读者最先看到的状态判断，例如 `当前可用`、`待复核`、`部分失效`、`仅作参考`。
- `status.verified`：最后验证情况。真正验证过时使用 `YYYY-MM-DD`；未重新验证的历史文章使用 `待复核`，避免伪造验证日期。
- `status.environment`：适用系统、工具、平台或上下文。
- `status.risk`：执行前必须知道的风险、边界或注意事项。

字段渲染规则：

- 只有 `status` 存在时才渲染整个状态块。
- `status` 存在但某个子字段为空时，跳过该行。
- 字段值全部按文本转义，不允许把 front matter 当 HTML 输出。
- `updated` 和 `status.verified` 分工不同：`updated` 表示文章正文最后实质更新日期，`status.verified` 表示方案最后验证情况。

## 维护规则

`status.verified` 由文章维护者手动维护，不由构建脚本、发布时间或当前日期自动生成。

只有实际复核过文章中的方案、命令、配置或流程后，才能把 `status.verified` 写成 `YYYY-MM-DD`。如果只是修改标题、SEO、分类、标签、样式、排版或站点模板，不得更新该字段。

如果正文方案发生实质更新，并且更新时同步复核了方案，通常同时更新：

```yaml
updated: YYYY-MM-DD
status:
  verified: YYYY-MM-DD
```

如果只更新正文说明但没有重新验证方案，更新 `updated`，但 `status.verified` 仍保持原日期或 `待复核`。

## 页面位置

状态信息块放在文章页标题日期区域之后、正文之前：

```liquid
<header class="post-header">...</header>
{%- include post-status.html -%}
<div class="post-content e-content" itemprop="articleBody">
```

这样读者在进入正文前先看到适用性和风险，不影响标题、日期、作者和正文结构。

## 初始历史文章状态

历史文章全部初始化，但不伪造外部验证。默认策略：

- 明确是个人规则、Prompt 或设计类内容，状态可标为 `当前可用`。
- 涉及外部工具、第三方服务、代理节点、桌面应用或系统配置的文章，状态标为 `待复核`。
- `verified` 只有在本次确实重新验证文章方案时才写日期；否则写 `待复核`。

初始字段建议：

| 文章 | label | verified | environment | risk |
|---|---|---|---|---|
| macOS Homebrew 加速 | 待复核 | 待复核 | macOS / Homebrew / pip / zsh | 会修改包管理源、终端代理和 shell 配置，执行前建议备份原配置。 |
| Claude Desktop 接入 DeepSeek | 待复核 | 待复核 | macOS / Claude Desktop / UpstreamKit / cc-switch | 第三方模型接口和客户端行为可能变化，涉及 API 配置时不要写入真实密钥。 |
| Git HTTP/SSH 自动代理 | 待复核 | 待复核 | Git HTTP/SSH / zsh / 本地代理 | 会修改 Git、SSH 或 shell 代理配置，执行前建议记录当前配置。 |
| Skillshare 上手指南 | 待复核 | 待复核 | Skillshare CLI / Claude / Codex Skills | 会影响本地 skills 目录和同步流程，执行前确认目标目录和备份策略。 |
| AGENTS.md 配置指南 | 当前可用 | 2026-06-28 | Codex / Claude / AGENTS.md | 这是个人协作规则模板，复用前应按自己的项目和工具链删改。 |
| Codex Desktop GPU 渲染异常 | 待复核 | 待复核 | Codex Desktop / Intel Mac / Electron GPU | 启动参数可能随客户端版本变化，仅适合作为同类渲染问题的排查参考。 |
| Clash Verge GitHub 节点测速 | 待复核 | 待复核 | Clash Verge / mihomo / GitHub 访问 | 节点质量和 GitHub 访问路径会变化，测速结果只代表执行时环境。 |
| 网络诊断与优化 AI Prompt | 当前可用 | 2026-06-28 | AI Agent / Windows、macOS 网络排障 | 只允许执行安全、可逆的诊断和优化；涉及系统网络配置时要先保留 before/after。 |
| World Cup Predictor Skill 设计 | 当前可用 | 2026-06-28 | AI Agent / World Cup Predictor Skill | 这是预测流程设计，不应当作确定性赛果或投注建议。 |

## 样式

状态块视觉应保持克制：

- 使用浅背景、细边框和 8px 以内圆角。
- 标题为“文章状态”。
- 每行用短标签加正文值展示。
- 移动端单列，不让标签和值挤压重叠。
- 不使用醒目的红色警告框，除非未来引入真正的 `danger` 状态。

## 测试

扩展 `test/site_features_test.rb`：

- 断言有 `status` 的文章渲染 `class="post-status"`。
- 断言状态块包含 `状态`、`最后验证`、`适用环境`、`风险提示`。
- 断言没有 `status` 的临时 fixture 或页面不渲染状态块。如果不引入 fixture，则断言普通非文章页面没有该块。
- 断言 `itemprop="dateModified"` 仍由 `updated` 控制，不能因为 `status.verified` 出现就自动生成。
- 断言样式包含 `.post-status`、`.post-status-title`、`.post-status-list`。

## 验收标准

- `.\bin\test.ps1` 运行成功。
- 文章页正文前出现状态信息块。
- 所有历史文章都有初始化的 `status` 字段。
- 没有 `status` 的页面不受影响。
- `updated`、SEO `dateModified` 和 `status.verified` 不互相混用。
- 不提交 `_site/`、缓存、依赖目录或环境文件。
