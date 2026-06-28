# 文章状态信息块实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 在文章页正文前渲染可维护的状态信息块，并为所有历史文章初始化状态字段。

**架构：** 使用文章 front matter 的 `status` 对象作为数据源，新增 `_includes/post-status.html` 专门渲染状态块，并在 `_layouts/post.html` 中标题区域后调用。样式放在 `_sass/theme/_posts.scss`，测试覆盖渲染、非文章页面不受影响、`dateModified` 不被 `status.verified` 影响。

**技术栈：** Jekyll 4、Liquid、SCSS、Minitest、PowerShell 测试入口 `.\bin\test.ps1`。

---

## 文件结构

- 修改 `docs/superpowers/specs/2026-06-28-post-status-block-design.md`：补充 `status.verified` 人工维护规则。
- 新建 `_includes/post-status.html`：渲染文章状态块。
- 修改 `_layouts/post.html`：在文章 header 后、正文前 include 状态块。
- 修改 `_sass/theme/_posts.scss`：增加状态块样式。
- 修改 `_posts/*.md`：给 9 篇历史文章初始化 `status`。
- 修改 `test/site_features_test.rb`：增加状态块行为和样式测试。

---

### Task 1: 写失败测试

**Files:**
- Modify: `test/site_features_test.rb`

- [x] **Step 1: 新增状态块行为测试**

在 `test/site_features_test.rb` 中新增：

```ruby
def test_post_pages_render_status_block_when_status_front_matter_exists
  html = read_site("posts/global-agents-context/index.html")
  styles = read_scss_sources

  assert_includes html, 'class="post-status"'
  assert_includes html, 'class="post-status-title"'
  assert_includes html, "文章状态"
  assert_includes html, "状态"
  assert_includes html, "当前可用"
  assert_includes html, "最后验证"
  assert_includes html, "2026-06-28"
  assert_includes html, "适用环境"
  assert_includes html, "Codex / Claude / AGENTS.md"
  assert_includes html, "风险提示"
  assert_includes html, "这是个人协作规则模板"
  assert_includes styles, ".post-status"
  assert_includes styles, ".post-status-title"
  assert_includes styles, ".post-status-list"
end
```

- [x] **Step 2: 新增非文章页面和 dateModified 测试**

在同一测试文件新增：

```ruby
def test_status_block_does_not_render_on_regular_pages
  html = read_site("about/index.html")

  refute_includes html, 'class="post-status"'
end

def test_status_verified_does_not_create_date_modified
  html = read_site("posts/global-agents-context/index.html")

  assert_includes html, "2026-06-28"
  refute_includes html, 'itemprop="dateModified"'
end
```

- [x] **Step 3: 运行测试确认失败**

Run:

```powershell
.\bin\test.ps1
```

Expected: FAIL，原因是文章还没有状态块 HTML 和 `.post-status` 样式。

---

### Task 2: 实现状态块 include、layout 和样式

**Files:**
- Create: `_includes/post-status.html`
- Modify: `_layouts/post.html`
- Modify: `_sass/theme/_posts.scss`

- [x] **Step 1: 新增 `_includes/post-status.html`**

使用 `page.status` 渲染状态块；每个字段为空时跳过对应行。所有输出用 `escape`：

```liquid
{%- if page.status -%}
  <section class="post-status" aria-labelledby="post-status-title">
    <h2 id="post-status-title" class="post-status-title">文章状态</h2>
    <dl class="post-status-list">
      {%- if page.status.label -%}
        <div>
          <dt>状态</dt>
          <dd>{{ page.status.label | escape }}</dd>
        </div>
      {%- endif -%}
      {%- if page.status.verified -%}
        <div>
          <dt>最后验证</dt>
          <dd>{{ page.status.verified | escape }}</dd>
        </div>
      {%- endif -%}
      {%- if page.status.environment -%}
        <div>
          <dt>适用环境</dt>
          <dd>{{ page.status.environment | escape }}</dd>
        </div>
      {%- endif -%}
      {%- if page.status.risk -%}
        <div>
          <dt>风险提示</dt>
          <dd>{{ page.status.risk | escape }}</dd>
        </div>
      {%- endif -%}
    </dl>
  </section>
{%- endif -%}
```

- [x] **Step 2: 在 `_layouts/post.html` 调用 include**

放在 `</header>` 之后、正文 `<div class="post-content e-content">` 之前：

```liquid
    </header>

    {%- include post-status.html -%}

    <div class="post-content e-content" itemprop="articleBody">
```

- [x] **Step 3: 增加 `_sass/theme/_posts.scss` 样式**

新增 `.post-status`、`.post-status-title`、`.post-status-list`、`.post-status-list div`、`.post-status-list dt`、`.post-status-list dd` 样式。状态块宽度跟文章正文一致，移动端自动单列。

- [x] **Step 4: 运行测试确认仍可能失败**

Run:

```powershell
.\bin\test.ps1
```

Expected: 由于历史文章还没有 `status` front matter，状态块测试仍失败。

---

### Task 3: 初始化历史文章状态字段

**Files:**
- Modify: `_posts/2026-04-25-macos-homebrew-acceleration.md`
- Modify: `_posts/2026-04-30-macos-claude-deepseek.md`
- Modify: `_posts/2026-05-04-auto-proxy-setup.md`
- Modify: `_posts/2026-05-04-skillshare-guide.md`
- Modify: `_posts/2026-05-12-global-agents-context.md`
- Modify: `_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`
- Modify: `_posts/2026-05-26-clash-verge-github-node-speed-test.md`
- Modify: `_posts/2026-06-06-ai-network-diagnosis-optimization-prompt.md`
- Modify: `_posts/2026-06-21-worldcup-predictor-agent-skill.md`

- [x] **Step 1: 按 spec 初始化 9 篇文章**

`_posts/2026-04-25-macos-homebrew-acceleration.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: macOS / Homebrew / pip / zsh
  risk: 会修改包管理源、终端代理和 shell 配置，执行前建议备份原配置。
```

`_posts/2026-04-30-macos-claude-deepseek.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: macOS / Claude Desktop / UpstreamKit / cc-switch
  risk: 第三方模型接口和客户端行为可能变化，涉及 API 配置时不要写入真实密钥。
```

`_posts/2026-05-04-auto-proxy-setup.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: Git HTTP/SSH / zsh / 本地代理
  risk: 会修改 Git、SSH 或 shell 代理配置，执行前建议记录当前配置。
```

`_posts/2026-05-04-skillshare-guide.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: Skillshare CLI / Claude / Codex Skills
  risk: 会影响本地 skills 目录和同步流程，执行前确认目标目录和备份策略。
```

`_posts/2026-05-12-global-agents-context.md`：

```yaml
status:
  label: 当前可用
  verified: 2026-06-28
  environment: Codex / Claude / AGENTS.md
  risk: 这是个人协作规则模板，复用前应按自己的项目和工具链删改。
```

`_posts/2026-05-17-codex-desktop-gpu-rendering-bug.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: Codex Desktop / Intel Mac / Electron GPU
  risk: 启动参数可能随客户端版本变化，仅适合作为同类渲染问题的排查参考。
```

`_posts/2026-05-26-clash-verge-github-node-speed-test.md`：

```yaml
status:
  label: 待复核
  verified: 待复核
  environment: Clash Verge / mihomo / GitHub 访问
  risk: 节点质量和 GitHub 访问路径会变化，测速结果只代表执行时环境。
```

`_posts/2026-06-06-ai-network-diagnosis-optimization-prompt.md`：

```yaml
status:
  label: 当前可用
  verified: 2026-06-28
  environment: AI Agent / Windows、macOS 网络排障
  risk: 只允许执行安全、可逆的诊断和优化；涉及系统网络配置时要先保留 before/after。
```

`_posts/2026-06-21-worldcup-predictor-agent-skill.md`：

```yaml
status:
  label: 当前可用
  verified: 2026-06-28
  environment: AI Agent / World Cup Predictor Skill
  risk: 这是预测流程设计，不应当作确定性赛果或投注建议。
```

- [x] **Step 2: 运行测试确认通过**

Run:

```powershell
.\bin\test.ps1
```

Expected: PASS。

---

### Task 4: 最终验证和提交

**Files:**
- All changed files

- [x] **Step 1: 检查 diff**

Run:

```powershell
git diff --stat
git diff --check
```

Expected: 只包含计划内文件，没有 whitespace error。

- [ ] **Step 2: 提交实现**

Run:

```powershell
git add docs/superpowers/specs/2026-06-28-post-status-block-design.md docs/superpowers/plans/2026-06-28-post-status-block.md _includes/post-status.html _layouts/post.html _sass/theme/_posts.scss test/site_features_test.rb _posts/*.md
git commit -m "Add post status blocks"
```

Expected: commit 成功，工作区干净。
