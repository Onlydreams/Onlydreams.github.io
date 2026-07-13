# 个人技术博客平衡修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 恢复本机完整测试能力，明确博客定位，收敛 taxonomy，并基于当前官方资料核验和修正 7 篇待复核文章。

**Architecture:** 保留现有 Jekyll 页面、permalink 和视觉体系，在现有页面、文章 front matter 与正文上做聚焦修改。行为契约继续集中在 `test/site_features_test.rb`，内容元数据约束继续集中在 `test/content_health_test.rb`；外部事实以官方文档、官方仓库、issue 和 release 为证据。

**Tech Stack:** Jekyll 4.4、Liquid、Ruby 3.3.11、Minitest、Markdown、YAML、GitHub Pages。

## Global Constraints

- 规格来源：`docs/superpowers/specs/2026-07-13-blog-balanced-maintenance-design.md`。
- 不增加依赖，不修改 `.ruby-version`、`Gemfile.lock`、文章 permalink、站名、域名或核心导航。
- 分类白名单：`AI`、`开发工具`、`网络与代理`、`浏览器`、`体育技术`；每篇文章一到两个分类。
- 无法从官方资料或当前环境确认的文章保持 `待复核`，不得推测为可用。
- 正文实质变化才设置 `updated: 2026-07-13`；不公开真实密钥、Token、代理节点、控制接口或个人路径。

---

### Task 1: 恢复 Ruby/Bundler 测试入口

**Files:** Verify `.ruby-version`、`Gemfile.lock`、`bin/preflight`；不修改仓库文件。

**Interfaces:** Consumes Ruby `3.3.11` 与 Bundler `2.5.22`；Produces 可运行 `bash bin/test` 的本机环境。

- [ ] **Step 1: 确认失败基线**

Run: `bash bin/test`

Expected: FAIL，明确报告 Ruby 3.3.11 缺少 Bundler 2.5.22。

- [ ] **Step 2: 安装 lockfile 指定版本**

Run with permission:

```bash
/usr/local/opt/ruby@3.3/bin/gem install bundler -v 2.5.22
```

Expected: 只为当前 Ruby 安装 Bundler，不写 shell profile 或持久环境变量。

- [ ] **Step 3: 验证基线**

```bash
/usr/local/opt/ruby@3.3/bin/bundle _2.5.22_ --version
bash bin/test
```

Expected: Bundler 2.5.22；现有完整测试通过。

### Task 2: 用失败测试定义定位与 taxonomy

**Files:** Modify `test/site_features_test.rb`、`test/content_health_test.rb`。

**Interfaces:** Consumes 构建后的首页、About 和文章 front matter；Produces 新文案、入口和 taxonomy 契约。

- [ ] **Step 1: 添加首页和 About 测试**

```ruby
def test_homepage_explains_the_blog_focus_and_starting_points
  html = read_site("index.html")
  assert_includes html, "AI Agent 工具链、开发环境与网络排障"
  assert_includes html, "从这里开始"
  assert_includes html, 'href="/series/#series-ai-agent"'
  assert_includes html, 'href="/series/#series-network-proxy"'
  assert_includes html, 'href="/status/"'
end

def test_about_page_explains_editorial_principles_and_site_identity
  html = read_site("about/index.html")
  %w[关注方向 写作原则 当前可用 待复核 已失效 Onlydreams dayjia.com].each do |text|
    assert_includes html, text
  end
  assert_includes html, 'href="/status/"'
end
```

- [ ] **Step 2: 添加分类与标签测试**

用以下常量替换旧 `CANONICAL_CATEGORY_NAMES`：

```ruby
ALLOWED_CATEGORIES = ["AI", "开发工具", "网络与代理", "浏览器", "体育技术"].freeze
FORBIDDEN_TAG_ALIASES = { "agents" => "agent" }.freeze
```

新增测试：

```ruby
def test_categories_use_the_stable_taxonomy
  posts.each do |post|
    categories = Array(post[:front_matter]["categories"])
    assert_includes 1..2, categories.size
    categories.each { |category| assert_includes ALLOWED_CATEGORIES, category }
  end
end

def test_tags_do_not_use_known_aliases
  posts.each do |post|
    Array(post[:front_matter]["tags"]).each do |tag|
      refute FORBIDDEN_TAG_ALIASES.key?(tag), "#{post[:relative_path]} should use #{FORBIDDEN_TAG_ALIASES[tag].inspect}"
    end
  end
end
```

删除旧 `test_category_casing_uses_existing_canonical_names`。

- [ ] **Step 3: 验证 RED 并提交测试**

Run: `bash bin/test`

Expected: FAIL，原因是新首页/About 内容不存在、旧分类不在白名单、`agents` 标签仍存在。

```bash
git add test/site_features_test.rb test/content_health_test.rb
git commit -m "test: define blog positioning and taxonomy"
```

### Task 3: 实现定位与 taxonomy 收敛

**Files:** Modify `index.html`、`about.md`、12 个 `_posts/*.md`；仅在必要时 modify `_sass/theme/_taxonomy-search.scss`。

**Interfaces:** Consumes Task 2 契约；Produces 具体价值主张、三个起步入口、稳定分类和统一 `agent` 标签。

- [ ] **Step 1: 更新首页**

使用标题“可复现的开发工具与 AI Agent 实践”和简介“聚焦 AI Agent 工具链、开发环境与网络排障，记录经过验证的配置、故障分析和风险边界。”在专题区前增加“从这里开始”，链接现有 `#series-ai-agent`、`#series-network-proxy` 和 `/status/`。

- [ ] **Step 2: 更新 About**

正文固定包含“关于我”“关注方向”“写作原则”“文章状态”“站名与域名”“联系方式”，并明确：`Onlydreams 是这个个人技术博客使用的站名，dayjia.com 是它的访问域名，两者指向同一站点。` 状态说明链接 `/status/`。

- [ ] **Step 3: 映射全部分类并统一标签**

```text
macos-homebrew-acceleration -> [开发工具, 网络与代理]
macos-claude-deepseek -> [AI, 开发工具]
auto-proxy-setup -> [网络与代理, 开发工具]
skillshare-guide -> [AI, 开发工具]
global-agents-context -> [AI]
codex-desktop-gpu-rendering-bug -> [AI, 开发工具]
clash-verge-github-node-speed-test -> [网络与代理]
ai-network-diagnosis-optimization-prompt -> [AI, 网络与代理]
worldcup-predictor-agent-skill -> [AI, 体育技术]
codex-rate-limit-reset-credits-expiry -> [AI, 开发工具]
zhihu-action-width-fix-userscript -> [浏览器]
codex-app-superpowers-plugin-missing -> [AI, 开发工具]
```

将 `global-agents-context` 的 `agents` 标签改为 `agent`；具体平台使用已有小写标签，避免新增同义词。

- [ ] **Step 4: 验证 GREEN 并提交**

Run: `bash bin/test`

Expected: PASS。

```bash
git add index.html about.md _posts
git commit -m "refactor: focus blog positioning and taxonomy"
```

若样式实际修改，再单独精确 stage 样式文件。

### Task 4: 更新稳定基础设施文章

**Files:** Modify Homebrew、Git 代理、GitHub 节点测速三篇文章。

**Interfaces:** Consumes Homebrew/USTC/pip/Git/GitHub 官方资料；Produces 三篇 `当前可用`、`verified: 2026-07-13` 的文章。

- [ ] **Step 1: Homebrew 与 pip**

- 用 `HOMEBREW_BREW_GIT_REMOTE` 替代直接修改 `brew --repo` remote。
- 保留 USTC 当前支持的 `HOMEBREW_BOTTLE_DOMAIN`、`HOMEBREW_API_DOMAIN`。
- 说明 `HOMEBREW_NO_AUTO_UPDATE=1` 会延迟安全更新，并给出手动更新或 `HOMEBREW_AUTO_UPDATE_SECS` 选项。
- HTTPS pip 镜像删除不必要的 `global.trusted-host`。
- 旧测速数字标成 2026-04-25 的历史样本，不作为当前排名。
- 添加官方参考，设置 `updated`、`label`、`verified`。

- [ ] **Step 2: Git HTTP/SSH 代理**

- 保留官方支持的 `http.proxy`、`https.proxy` 和 SSH `ProxyCommand`。
- `.zshenv` 改为确实需要所有 zsh 子进程继承时的可选方案，默认推荐按需函数和 Git 配置。
- 取消配置使用 `--unset-all` 并允许键不存在；添加 Git 官方参考。
- 设置 `updated: 2026-07-13`、`当前可用`、`verified: 2026-07-13`。

- [ ] **Step 3: GitHub 节点测速**

- 保留六域名分层和“delay 不等于吞吐”。
- 用 GitHub 官方资料说明 `codeload`、`objects`、`release-assets` 用途及域名清单并非永久完整清单。
- v2.92.0 下载资产标成核验时存在的示例，提示未来改用当前 release。
- 设置 `updated: 2026-07-13`、`当前可用`、`verified: 2026-07-13`。

- [ ] **Step 4: 验证并提交**

Run: `bash bin/test`

Expected: PASS，无敏感信息命中。

```bash
git add _posts/2026-04-25-macos-homebrew-acceleration.md _posts/2026-05-04-auto-proxy-setup.md _posts/2026-05-26-clash-verge-github-node-speed-test.md
git commit -m "docs: refresh development network guides"
```

### Task 5: 更新快速变化的 AI 工具文章

**Files:** Modify Claude/DeepSeek、Skillshare、Codex Intel GPU、Superpowers 插件四篇文章。

**Interfaces:** Consumes UpstreamKit v1.1.5、CC Switch v3.16.5、Skillshare 官方仓库/本机 v0.19.23 help、openai/codex #18774/#31365；Produces 明确证据边界的四篇文章。

- [ ] **Step 1: Claude Desktop / DeepSeek**

删除会诱导继续操作的 `deepseek-v4-pro` 直连步骤，将其改成已失效历史方案；当前路径说明本地兼容代理负责协议转换和模型映射。记录 UpstreamKit v1.1.5 与 CC Switch v3.16.5 的当前能力，不提供未经实测的模型 ID、端口或 Key。因没有第三方 Key 做端到端调用，保持 `待复核`，设置 `verified: 2026-07-13`、`updated: 2026-07-13`，风险明确“项目能力已确认，端到端调用未复测”。

- [ ] **Step 2: Skillshare**

Homebrew 命令改为 `brew install skillshare`；说明本机 v0.19.23 与官方最新 release 可能有命令差异，以 `skillshare <command> --help` 为本机真相。`collect --all` 改为迁移旧目录时的可选操作，先 `--dry-run`，并强调 source directory 是 source of truth、不要回灌默认或无关 target-local skills。设置 `当前可用`、`verified`、`updated` 为 2026-07-13。

- [ ] **Step 3: Codex Intel GPU**

记录 #18774 截至 2026-07-13 仍 open；issue 仅作为同类症状跟踪入口，不声称参数来自 issue 正文。将 `--force_high_performance_gpu` 限定为特定 Intel Mac 的历史实测 workaround。当前机器无法复现，保持 `待复核`，设置 `verified`、`updated` 为 2026-07-13。

- [ ] **Step 4: Superpowers 插件**

记录 #31365 截至 2026-07-13 仍 open；保留“新会话实际技能列表才是验证标准”和重装 workaround；继续把根因写成证据支持的可能性。设置 `当前可用`、`verified`、`updated` 为 2026-07-13。

- [ ] **Step 5: 验证并提交**

Run: `bash bin/test`

Expected: PASS。

```bash
git add _posts/2026-04-30-macos-claude-deepseek.md _posts/2026-05-04-skillshare-guide.md _posts/2026-05-17-codex-desktop-gpu-rendering-bug.md _posts/2026-07-12-codex-app-superpowers-plugin-missing.md
git commit -m "docs: verify fast-moving AI tool guides"
```

### Task 6: 最终验证和收口

**Files:** Verify all modified files；不保留临时文件或构建产物。

**Interfaces:** Consumes Tasks 1–5；Produces 可构建、无敏感信息、无无关改动的最终工作树。

- [ ] **Step 1: 运行完整验证**

```bash
bash bin/test
git diff --check
git status --short --branch
```

Expected: 完整测试 0 failures / 0 errors；diff check 无输出。

- [ ] **Step 2: 核对元数据**

```bash
ruby -r yaml -r date -e 'Dir["_posts/*.md"].sort.each { |path| text = File.read(path); data = YAML.safe_load(text.match(/\A---\s*\n(.*?)\n---\s*\n/m)[1], permitted_classes: [Date, Time], aliases: true); puts [File.basename(path), Array(data["categories"]).join("|"), data.dig("status", "label"), data.dig("status", "verified")].join("\t") }'
```

Expected: 分类全部来自白名单；7 篇核验文章 `verified` 均为 2026-07-13；未端到端复现的文章仍为 `待复核`。

- [ ] **Step 3: 审计提交和未跟踪文件**

```bash
git log -6 --oneline
git ls-files --others --exclude-standard
```

Expected: 只有本次规格、测试、定位/taxonomy 和文章更新提交；没有临时文件。
