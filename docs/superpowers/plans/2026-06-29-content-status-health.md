# 文章状态汇总与内容健康检查实现计划

> **给 agentic workers：** 必须使用子技能 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 按任务执行本计划。所有步骤使用 checkbox（`- [ ]`）语法跟踪进度。

**目标：** 新增公开的文章状态汇总页，并把内容健康检查接入现有测试流程，避免过期、风险较高或元数据不一致的文章被无声发布。

**架构：** 继续以文章 front matter 作为唯一数据源。`status.md` 用 Liquid 静态生成 `/status/` 页面；`test/content_health_test.rb` 用 Ruby/Minitest 校验文章元数据、状态字段、日期、系列顺序、分类大小写和常见敏感内容模式。

**技术栈：** Jekyll 4、Liquid、SCSS、Ruby Minitest、Bundler、Bash 测试入口 `./bin/test`、PowerShell 测试入口 `.\bin\test.ps1`。

---

## 文件结构

- 新建 `status.md`：生成 `/status/` 页面，按 `status.label` 分组展示文章。
- 修改 `_config.yml`：把 `status.md` 加入 `header_pages`，让导航展示“文章状态”。
- 修改 `_sass/theme/_taxonomy-search.scss`：增加状态页样式，沿用 taxonomy/series 页面的列表式风格。
- 修改 `test/site_features_test.rb`：覆盖状态页渲染、导航、样式和 `header_pages` allowlist。
- 新建 `test/content_health_test.rb`：校验文章 front matter、状态元数据、未来日期、系列排序、分类大小写和常见密钥模式。
- 修改 `bin/test`：在现有站点功能测试后运行 `test/content_health_test.rb`。
- 修改 `bin/test.ps1`：在 Windows/PowerShell 测试入口中同步运行内容健康检查。
- 修改 `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`：把分类 `macOS` 统一为站内既有分类名 `MacOS`。

---

### Task 1: 先写失败的状态页测试

**Files:**
- Modify: `test/site_features_test.rb`

- [ ] **Step 1: 新增状态页分组渲染测试**

在现有 taxonomy 和 series 测试附近加入：

```ruby
def test_status_page_groups_posts_by_status
  html = read_site("status/index.html")
  styles = read_scss_sources

  assert_includes html, "文章状态"
  assert_includes html, "当前可用"
  assert_includes html, "待复核"
  assert_includes html, "/posts/global-agents-context/"
  assert_includes html, "/posts/worldcup-predictor-agent-skill/"
  assert_includes html, "/posts/macos-homebrew-acceleration/"
  assert_includes html, "Codex / Claude / AGENTS.md"
  assert_includes html, "会修改包管理源、终端代理和 shell 配置"
  assert_includes html, 'class="status-post-list"'
  assert_includes html, 'class="status-post-risk"'
  assert_includes styles, ".status-page"
  assert_includes styles, ".status-section"
  assert_includes styles, ".status-post-risk"
end
```

- [ ] **Step 2: 更新导航和 header allowlist 测试**

把 `test_site_navigation_uses_explicit_page_allowlist` 改为：

```ruby
def test_site_navigation_uses_explicit_page_allowlist
  config = YAML.load_file(File.join(ROOT, "_config.yml"))

  assert_equal(
    ["about.md", "categories.md", "search.md", "series.md", "status.md", "tags.md"],
    config["header_pages"]
  )
end
```

在 `test_site_navigation_links_to_series_page` 附近新增：

```ruby
def test_site_navigation_links_to_status_page
  html = read_site("index.html")

  assert_includes html, 'href="/status/"'
  assert_includes html, ">文章状态</a>"
end
```

- [ ] **Step 3: 运行测试确认失败**

Run:

```bash
./bin/test
```

Expected: FAIL。原因是 `_site/status/index.html` 尚不存在，且 `_config.yml` 还没有配置 `status.md`。

---

### Task 2: 实现 `/status/` 页面和导航

**Files:**
- Create: `status.md`
- Modify: `_config.yml`
- Modify: `_sass/theme/_taxonomy-search.scss`

- [ ] **Step 1: 新建 `status.md`**

创建文件：

```liquid
---
layout: page
title: 文章状态
permalink: /status/
---

<div class="status-page">
  <p class="status-intro">按可用性查看文章，优先识别当前可用、待复核或风险较高的技术笔记。</p>

  {%- assign status_labels = "当前可用|待复核|已失效" | split: "|" -%}
  {%- for status_label in status_labels -%}
    {%- assign status_post_count = 0 -%}
    {%- for post in site.posts -%}
      {%- assign post_status_label = post.status.label | default: "未标记" -%}
      {%- if post_status_label == status_label -%}
        {%- assign status_post_count = status_post_count | plus: 1 -%}
      {%- endif -%}
    {%- endfor -%}

    {%- if status_post_count > 0 -%}
      <section class="status-section" id="status-{{ status_label | slugify: 'raw' }}">
        <header class="status-section-header">
          <h2>{{ status_label | escape }}</h2>
          <span class="status-count">{{ status_post_count }} 篇</span>
        </header>
        <ul class="status-post-list">
          {%- for post in site.posts -%}
            {%- assign post_status_label = post.status.label | default: "未标记" -%}
            {%- if post_status_label == status_label -%}
              <li>
                <article>
                  <h3>
                    <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
                  </h3>
                  <dl class="status-post-meta">
                    {%- if post.status.verified -%}
                      <div>
                        <dt>最后验证</dt>
                        <dd>{{ post.status.verified | escape }}</dd>
                      </div>
                    {%- endif -%}
                    {%- if post.status.environment -%}
                      <div>
                        <dt>适用环境</dt>
                        <dd>{{ post.status.environment | escape }}</dd>
                      </div>
                    {%- endif -%}
                  </dl>
                  {%- if post.status.risk -%}
                    <p class="status-post-risk">{{ post.status.risk | escape }}</p>
                  {%- endif -%}
                </article>
              </li>
            {%- endif -%}
          {%- endfor -%}
        </ul>
      </section>
    {%- endif -%}
  {%- endfor -%}
</div>
```

- [ ] **Step 2: 把 `status.md` 加入导航 allowlist**

把 `_config.yml` 中的 `header_pages` 改为：

```yaml
header_pages:
  - about.md
  - categories.md
  - search.md
  - series.md
  - status.md
  - tags.md
```

- [ ] **Step 3: 添加状态页样式**

在 `_sass/theme/_taxonomy-search.scss` 中，把下面代码放在 series page 样式之后、search page 样式之前：

```scss
/* ---- Status Page ---- */
html body .status-page {
  margin-top: 1.5rem;
}

html body .status-intro {
  margin-bottom: 2rem;
}

html body .status-section {
  padding: 1.5rem 0;
  border-top: 1px solid var(--border-color);
}

html body .status-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
}

html body .status-section-header h2 {
  margin: 0;
}

html body .status-count {
  flex-shrink: 0;
  padding: 0.18rem 0.55rem;
  border: 1px solid var(--border-color);
  border-radius: 999px;
  color: var(--text-muted);
  font-size: 0.78rem;
  line-height: 1.4;
}

html body .status-post-list {
  margin: 0;
  padding-left: 0;
  list-style: none;
}

html body .status-post-list li {
  padding: 1rem 0;
  border-top: 1px solid var(--border-color);
}

html body .status-post-list h3 {
  margin-top: 0;
  margin-bottom: 0.6rem;
  font-size: 1.08rem;
}

html body .status-post-list h3 a {
  color: var(--text-primary);
}

html body .status-post-meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.75rem 1rem;
  margin: 0;
}

html body .status-post-meta div {
  min-width: 0;
}

html body .status-post-meta dt {
  color: var(--text-muted);
  font-size: 0.78rem;
}

html body .status-post-meta dd {
  margin-left: 0;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

html body .status-post-risk {
  margin: 0.7rem 0 0;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

@media screen and (max-width: 600px) {
  html body .status-section-header {
    align-items: flex-start;
    flex-direction: column;
  }

  html body .status-post-meta {
    grid-template-columns: 1fr;
  }
}
```

- [ ] **Step 4: 运行站点功能测试**

Run:

```bash
./bin/test
```

Expected: `test_status_page_groups_posts_by_status`、`test_site_navigation_links_to_status_page` 和更新后的 header allowlist 测试通过。Task 3 接入更严格的内容健康检查后，完整命令可能会因内容健康检查失败。

- [ ] **Step 5: 提交状态页改动**

Run:

```bash
git add status.md _config.yml _sass/theme/_taxonomy-search.scss test/site_features_test.rb
git commit -m "feat: add article status page"
```

Expected: commit 成功，且只包含状态页和站点功能测试相关文件。

---

### Task 3: 添加失败的内容健康检查

**Files:**
- Create: `test/content_health_test.rb`
- Modify: `bin/test`
- Modify: `bin/test.ps1`

- [ ] **Step 1: 新建 `test/content_health_test.rb`**

创建文件：

```ruby
# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "time"
require "yaml"

class ContentHealthTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  POST_PATHS = Dir[File.join(ROOT, "_posts/*.md")].sort.freeze
  REQUIRED_FRONT_MATTER_KEYS = %w[layout title date categories tags status].freeze
  REQUIRED_STATUS_KEYS = %w[label verified environment risk].freeze
  ALLOWED_STATUS_LABELS = ["当前可用", "待复核", "已失效"].freeze
  CANONICAL_CATEGORY_NAMES = {
    "macos" => "MacOS"
  }.freeze
  SENSITIVE_PATTERNS = {
    "GitHub noreply email" => /users\.noreply\.github\.com/i,
    "OpenAI-style API key" => /\bsk-[A-Za-z0-9_-]{20,}\b/,
    "GitHub personal access token" => /\bghp_[A-Za-z0-9_]{20,}\b/,
    "Slack token" => /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/,
    "raw bearer token" => /Authorization:\s*Bearer\s+(?!<TOKEN>|YOUR_TOKEN|set-your-secret)[A-Za-z0-9._~+\/=-]{12,}/i
  }.freeze

  def posts
    POST_PATHS.map do |path|
      front_matter, body = split_front_matter(path)
      {
        path: path,
        relative_path: path.delete_prefix("#{ROOT}/"),
        front_matter: front_matter,
        body: body
      }
    end
  end

  def test_all_posts_have_required_front_matter
    posts.each do |post|
      missing_keys = REQUIRED_FRONT_MATTER_KEYS.reject do |key|
        value = post[:front_matter][key]
        value.respond_to?(:empty?) ? !value.empty? : !value.nil?
      end

      assert_empty missing_keys, "#{post[:relative_path]} missing front matter keys: #{missing_keys.join(", ")}"
      assert_equal "post", post[:front_matter]["layout"], "#{post[:relative_path]} must use layout: post"
    end
  end

  def test_post_dates_are_not_future_dates
    now = Time.now

    posts.each do |post|
      date = coerce_time(post[:front_matter]["date"])

      assert_operator date, :<=, now, "#{post[:relative_path]} has future date #{date}"
    end
  end

  def test_status_metadata_is_complete_and_consistent
    posts.each do |post|
      status = post[:front_matter]["status"] || {}
      missing_keys = REQUIRED_STATUS_KEYS.reject do |key|
        value = status[key]
        value.respond_to?(:strip) ? !value.strip.empty? : !value.nil?
      end

      assert_empty missing_keys, "#{post[:relative_path]} missing status keys: #{missing_keys.join(", ")}"
      assert_includes ALLOWED_STATUS_LABELS, status["label"], "#{post[:relative_path]} has unsupported status label #{status["label"].inspect}"

      if status["label"] == "当前可用"
        assert_match(/\A\d{4}-\d{2}-\d{2}\z/, status["verified"].to_s, "#{post[:relative_path]} current posts must use ISO verified date")
      end
    end
  end

  def test_series_posts_have_matching_series_order
    posts.each do |post|
      series = Array(post[:front_matter]["series"])
      next if series.empty?

      series_order = post[:front_matter]["series_order"] || {}
      missing_order = series.reject { |series_key| series_order.key?(series_key) }

      assert_empty missing_order, "#{post[:relative_path]} missing series_order keys: #{missing_order.join(", ")}"
    end
  end

  def test_category_casing_uses_existing_canonical_names
    posts.each do |post|
      Array(post[:front_matter]["categories"]).each do |category|
        canonical = CANONICAL_CATEGORY_NAMES[category.to_s.downcase]
        next unless canonical

        assert_equal canonical, category, "#{post[:relative_path]} should use category #{canonical.inspect} instead of #{category.inspect}"
      end
    end
  end

  def test_public_posts_do_not_contain_common_secret_patterns
    posts.each do |post|
      text = [post[:front_matter].to_s, post[:body]].join("\n")

      SENSITIVE_PATTERNS.each do |name, pattern|
        refute_match pattern, text, "#{post[:relative_path]} appears to contain #{name}"
      end
    end
  end

  private

  def split_front_matter(path)
    content = File.read(path)
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)

    refute_nil match, "#{path.delete_prefix("#{ROOT}/")} must start with YAML front matter"

    [
      YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true),
      match[2]
    ]
  end

  def coerce_time(value)
    case value
    when Time
      value
    when Date
      value.to_time
    else
      Time.parse(value.to_s)
    end
  end
end
```

- [ ] **Step 2: 接入 Bash 测试入口**

把 `bin/test` 改为：

```bash
#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build
bundle exec ruby test/site_features_test.rb
bundle exec ruby test/content_health_test.rb
```

- [ ] **Step 3: 接入 PowerShell 测试入口**

把 `bin/test.ps1` 改为：

```powershell
$ErrorActionPreference = "Stop"

bundle exec jekyll build
bundle exec ruby test/site_features_test.rb
bundle exec ruby test/content_health_test.rb
```

- [ ] **Step 4: 运行内容健康检查并确认失败**

Run:

```bash
bundle exec ruby test/content_health_test.rb
```

Expected: FAIL。失败原因应指向 `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md` 的分类大小写不一致：当前使用 `macOS`，站内既有规范分类是 `MacOS`。

---

### Task 4: 修正文章元数据并验证健康检查

**Files:**
- Modify: `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`

- [ ] **Step 1: 统一 Codex Desktop 文章分类**

在 `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md` 中，把：

```yaml
categories: [AI, 工具, macOS]
```

改为：

```yaml
categories: [AI, 工具, MacOS]
```

- [ ] **Step 2: 运行内容健康检查**

Run:

```bash
bundle exec ruby test/content_health_test.rb
```

Expected: PASS，所有内容健康检查通过。

- [ ] **Step 3: 运行完整测试入口**

Run:

```bash
./bin/test
```

Expected: PASS。该命令会构建 Jekyll 站点，运行 `test/site_features_test.rb`，再运行 `test/content_health_test.rb`。

- [ ] **Step 4: 检查生成后的状态页输出**

Run:

```bash
grep -n "文章状态" _site/status/index.html
grep -n "当前可用" _site/status/index.html
grep -n "待复核" _site/status/index.html
```

Expected: 每条命令至少打印一行来自 `_site/status/index.html` 的匹配内容。

- [ ] **Step 5: 检查 diff 卫生**

Run:

```bash
git diff --check
git diff --stat
```

Expected: `git diff --check` 无输出。`git diff --stat` 只包含 `status.md`、`_config.yml`、`_sass/theme/_taxonomy-search.scss`、`test/site_features_test.rb`、`test/content_health_test.rb`、`bin/test`、`bin/test.ps1` 和 `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`。

- [ ] **Step 6: 提交内容健康检查改动**

Run:

```bash
git add bin/test bin/test.ps1 test/content_health_test.rb _posts/2026-05-17-codex-desktop-gpu-rendering-bug.md
git commit -m "test: add content health checks"
```

Expected: commit 成功，且只包含内容健康检查和元数据规范化相关文件。

---

### Task 5: 最终复核

**Files:**
- Review: `status.md`
- Review: `_config.yml`
- Review: `_sass/theme/_taxonomy-search.scss`
- Review: `test/site_features_test.rb`
- Review: `test/content_health_test.rb`
- Review: `bin/test`
- Review: `bin/test.ps1`
- Review: `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`

- [ ] **Step 1: 复核公开内容边界**

Run:

```bash
bundle exec ruby test/content_health_test.rb
```

Expected: PASS。该结果确认公开文章没有命中 `SENSITIVE_PATTERNS` 中定义的常见敏感内容模式。

- [ ] **Step 2: 复核导航顺序**

Run:

```bash
grep -n "header_pages" -A8 _config.yml
```

Expected: 输出显示 `status.md` 位于 `series.md` 和 `tags.md` 之间。

- [ ] **Step 3: 最终完整验证**

Run:

```bash
./bin/test
```

Expected: PASS。

- [ ] **Step 4: 查看最终工作树状态**

Run:

```bash
git status --short --branch
```

Expected: 如果执行过程中按计划提交了两个 commit，工作树应为 clean；如果实现者选择暂不提交，只应剩下计划内文件的 intentional uncommitted changes。
