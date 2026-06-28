# 专题页实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 为 Jekyll 博客新增静态生成的 `/series/` 专题页，把现有相关文章按专题聚合展示。

**架构：** 使用 `_data/series.yml` 维护专题元数据，文章 front matter 维护 `series` 和 `series_order`。`series.md` 只负责静态 Liquid 渲染，不引入插件或客户端渲染。

**技术栈：** Jekyll 4、Liquid、SCSS、Minitest、PowerShell 测试入口 `.\bin\test.ps1`。

---

## 文件结构

- 新建 `_data/series.yml`：专题 key、标题、说明和展示顺序。
- 新建 `series.md`：生成 `/series/` 页面。
- 修改 `_posts/*.md`：给现有文章补充 `series` 和 `series_order`。
- 修改 `_sass/theme/_taxonomy-search.scss`：增加专题页样式，复用 taxonomy/search 风格。
- 修改 `test/site_features_test.rb`：新增专题页生成、导航和代表性内容测试。
- 保留 `docs/superpowers/specs/2026-06-28-series-page-design.md`：已确认设计文档。

---

### Task 1: 写失败测试

**Files:**
- Modify: `test/site_features_test.rb`

- [ ] **Step 1: 新增专题页测试**

在 `test/site_features_test.rb` 中新增测试方法：

```ruby
def test_series_page_lists_configured_series_and_posts
  html = read_site("series/index.html")

  assert_includes html, "专题"
  assert_includes html, "AI Agent 工作流"
  assert_includes html, "网络与代理排障"
  assert_includes html, "macOS 开发工具链"
  assert_includes html, "/posts/skillshare-guide/"
  assert_includes html, "/posts/auto-proxy-setup/"
  assert_includes html, "/posts/macos-claude-deepseek/"
  assert_includes html, 'class="series-post-tags"'
end
```

同时新增导航断言：

```ruby
def test_site_navigation_links_to_series_page
  html = read_site("index.html")

  assert_includes html, 'href="/series/"'
  assert_includes html, ">专题</a>"
end
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
.\bin\test.ps1
```

Expected: FAIL，原因是 `_site/series/index.html` 不存在或导航中没有 `/series/`。

---

### Task 2: 实现专题数据和页面

**Files:**
- Create: `_data/series.yml`
- Create: `series.md`
- Modify: `_posts/2026-04-25-macos-homebrew-acceleration.md`
- Modify: `_posts/2026-04-30-macos-claude-deepseek.md`
- Modify: `_posts/2026-05-04-auto-proxy-setup.md`
- Modify: `_posts/2026-05-04-skillshare-guide.md`
- Modify: `_posts/2026-05-12-global-agents-context.md`
- Modify: `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`
- Modify: `_posts/2026-05-26-clash-verge-github-node-speed-test.md`
- Modify: `_posts/2026-06-06-ai-network-diagnosis-optimization-prompt.md`
- Modify: `_posts/2026-06-21-worldcup-predictor-agent-skill.md`

- [ ] **Step 1: 新增 `_data/series.yml`**

```yaml
- key: ai-agent
  title: AI Agent 工作流
  description: Codex、Claude、Skills 与 Agent 协作规则相关笔记。
- key: network-proxy
  title: 网络与代理排障
  description: 代理、DNS、GitHub 访问和网络诊断相关经验。
- key: macos-tooling
  title: macOS 开发工具链
  description: macOS 开发环境、AI 工具和桌面端问题处理记录。
```

- [ ] **Step 2: 新增 `series.md`**

页面 front matter：

```yaml
---
layout: page
title: 专题
permalink: /series/
---
```

页面主体使用 Liquid 遍历 `site.data.series`，对每个专题筛选 `site.posts` 中 `post.series contains series.key` 的文章，先渲染 `series_order` 为 1 到 20 的文章，再渲染没有该 key 顺序的文章。

- [ ] **Step 3: 补充文章 front matter**

给设计文档列出的现有文章补充：

```yaml
series: [ai-agent]
series_order:
  ai-agent: 1
```

多专题文章使用数组和多 key 顺序，例如：

```yaml
series: [network-proxy, macos-tooling]
series_order:
  network-proxy: 1
  macos-tooling: 1
```

- [ ] **Step 4: 运行测试确认通过新增行为**

Run:

```powershell
.\bin\test.ps1
```

Expected: PASS，若样式断言尚未加入则至少专题页和导航测试通过。

---

### Task 3: 补充样式和最终验证

**Files:**
- Modify: `_sass/theme/_taxonomy-search.scss`
- Modify: `test/site_features_test.rb`

- [ ] **Step 1: 增加专题页样式**

在 taxonomy/search 样式文件中增加 `.series-page`、`.series-section`、`.series-post-list`、`.series-post-tags` 等选择器。布局保持列表式，不做嵌套卡片。

- [ ] **Step 2: 增加样式存在性测试**

在专题页测试中读取 `read_scss_sources` 并断言包含：

```ruby
assert_includes styles, ".series-page"
assert_includes styles, ".series-section"
assert_includes styles, ".series-post-tags"
```

- [ ] **Step 3: 运行完整测试**

Run:

```powershell
.\bin\test.ps1
```

Expected: PASS，输出无失败。

- [ ] **Step 4: 检查 git diff**

Run:

```powershell
git diff --stat
git diff --check
```

Expected: 只包含计划内文件，没有 whitespace error。
