# 专题页设计

## 目标

新增一个轻量的 `/series/` 页面，把相关博客文章组织成可顺序阅读的专题集合。第一版重点解决文章发现和阅读路径问题，不新增 Jekyll 插件、运行时 JavaScript，也不做大规模视觉改版。

## 范围

本次包含：

- 新增 `/series/` 页面，按文章 front matter 里的 `series` key 分组展示。
- 新增 `_data/series.yml`，集中维护专题标题、说明和展示顺序。
- 给现有文章补充明确的专题元数据。
- 给站点导航新增“专题”入口。
- 增加少量样式，保持和当前分类页、文章列表风格一致。
- 补充生成结果和导航相关测试。

本次不包含：

- 文章状态信息块。
- 搜索排序或命中高亮。
- 单篇文章页里的“本系列其他文章”导航。
- Newsletter、Open Graph 图片生成、访问统计或视觉重设计。
- 任何新的 Jekyll 插件或依赖。

## 内容模型

专题元数据放在 `_data/series.yml`：

```yaml
- key: ai-agent
  title: AI Agent 工作流
  description: Codex、Claude、Skills 与 Agent 协作规则相关笔记。
```

文章可选增加这些 front matter 字段：

```yaml
series: [ai-agent, macos-tooling]
series_order:
  ai-agent: 2
  macos-tooling: 3
```

字段行为：

- `series` 是稳定的机器 key 数组，用于把文章归入一个或多个专题。
- `_data/series.yml` 提供 `/series/` 页面展示用的专题标题和说明。
- `series_order` 是可选映射，用于控制文章在各专题内的顺序；数字越小越靠前。
- 没有 `series` 的文章不出现在专题页。
- 如果文章引用了 `_data/series.yml` 中不存在的 key，第一版不为它生成可见专题区块。
- 如果某个 key 缺少 `series_order`，对应文章排在有顺序的文章后面，再按发布时间排序。

## 初始专题

先把现有文章归入这些专题：

- `ai-agent` / `AI Agent 工作流`
  - Skillshare guide
  - AGENTS.md configuration guide
  - Codex Desktop GPU rendering bug
  - World Cup Predictor skill article
- `network-proxy` / `网络与代理排障`
  - macOS Homebrew acceleration
  - Git HTTP/SSH auto proxy setup
  - Clash Verge GitHub node speed test
  - Network diagnosis prompt
- `macos-tooling` / `macOS 开发工具链`
  - macOS Homebrew acceleration
  - Claude Desktop DeepSeek setup
  - Codex Desktop GPU rendering bug

如果能明显改善发现路径，一篇文章可以属于多个专题。但每篇文章的专题数量应保持克制，避免归档变得松散。

## 页面行为

`/series/` 页面应满足：

- 使用现有 `page` layout。
- 对 `_data/series.yml` 中有匹配文章的每个专题渲染一个区块。
- 每个专题展示标题、文章数量和文章列表。
- 每篇文章展示标题、发布日期、可选更新日期、摘要和最多 5 个标签。
- 专题区块顺序以 `_data/series.yml` 中的顺序为准。
- 专题内文章先按 `series_order` 排序，再按发布时间排序。
- 不依赖客户端渲染，生成后的静态 HTML 应可直接浏览。

## 导航

在可见站点导航中新增“专题”，链接指向 `/series/`。

## 样式

沿用当前站点克制的视觉语言：

- 页面宽度继续使用现有 layout 的内容约束。
- 专题区块更接近当前 taxonomy 页面，而不是营销式卡片。
- 单篇文章条目可以复用文章卡片的间距感，但避免卡片套卡片。
- 移动端要保证标题、日期、标签和摘要不重叠。

## 测试

扩展 `test/site_features_test.rb`，断言：

- `_site/series/index.html` 存在并包含“专题”。
- 页面列出初始专题标题。
- 代表性文章出现在预期专题中。
- 站点导航包含 `/series/` 链接。
- 现有构建和功能测试继续通过 `.\bin\test.ps1`。

## 验收标准

- `.\bin\test.ps1` 运行成功。
- `/series/` 在构建产物中可直接渲染，不依赖 JavaScript。
- 至少展示 3 个初始专题。
- 没有 `series` 的现有文章仍能正常构建。
- 不提交 `_site/`、缓存、依赖目录或环境文件。
