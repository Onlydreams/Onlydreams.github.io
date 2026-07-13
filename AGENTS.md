# 仓库协作指南

本仓库是一个 Jekyll 静态博客站点。

## 开发环境

- Ruby 版本以 `.ruby-version` 为准。
- 使用 Bundler 管理依赖。
- 项目依赖默认安装到本地目录，避免污染全局 Ruby 环境。
- 日常操作必须使用仓库的 toolchain 入口；不要直接运行裸 `bundle`，除非正在针对 Bundler 本身排障。
- 不要持久设置 `BUNDLE_PATH`、`GEM_HOME`、`GEM_PATH` 或 `RUBYOPT`；入口脚本会在当前进程隔离这些变量，避免不同 Ruby 版本互相污染。

## 常用命令

在仓库根目录执行一次初始化：

```powershell
.\bin\setup.ps1
```

在 Windows PowerShell 日常执行：

```powershell
.\bin\test.ps1
.\bin\serve.ps1
```

在 macOS / Linux 日常执行：

```bash
bash bin/setup
bash bin/test
bash bin/serve
```

## 目录结构

- `_posts/`：博客文章。
- `_layouts/`：页面布局模板。
- `_includes/`：可复用模板片段。
- `_plugins/`：本地 Jekyll 插件。
- `assets/`：静态资源。
- `_site/`：Jekyll 构建产物，不应提交。

## 编辑约定

- 站点内容以中文为主，Markdown 文件保持 UTF-8 编码。
- 修改应保持小而聚焦，避免无关重构。
- 改动站点配置时，留意 `_config.yml` 中的 `exclude`、`plugins`、分页和 SEO 相关设置。
- `docs/superpowers/specs/`、`docs/superpowers/plans/` 等内部设计、规格和实现计划文档默认使用简体中文，除非用户明确要求英文。
- 不要提交本地缓存、依赖目录、构建产物、日志、环境变量文件或编辑器私有配置。

## 公开联系信息

- 不要把 GitHub `users.noreply.github.com` 地址作为公开联系邮箱；这类地址通常不能正常收信。
- 公开联系入口优先使用 GitHub、文章评论或其他已确认可用的渠道；只有确认域名邮箱已完成收发配置后，才在站点展示公开邮箱。

## 博客文章生成约定

- 新文章放在 `_posts/`，文件名格式为 `YYYY-MM-DD-slug.md`。
- 必须使用 YAML front matter，至少包含 `layout: post`、`title`、`date`、`categories`、`tags` 和 `status`；只有文章经过实质更新时才添加 `updated: YYYY-MM-DD`。
- `status` 至少包含 `label`、`verified`、`environment` 和 `risk`；`label` 只使用 `当前可用`、`待复核`、`已失效`。
- `verified` 统一使用 `YYYY-MM-DD`，表示最近一次完成文中所声明核验范围的日期，不自动代表已完成端到端复测。
- `当前可用` 表示核心操作已在声明环境中验证；只确认了官方资料、项目能力、issue 状态或历史 workaround，但未完成当前环境复测时，使用 `待复核`，并在 `risk` 中写明尚未验证的部分；确认方案不可继续使用时标记为 `已失效`。
- `date` 必须早于当前实际构建时间，禁止写未来时间；不确定时使用当前时间向前取整或提前 5-10 分钟，避免 Jekyll 将文章当作未来文章跳过。
- 文章标题放在 front matter 的 `title` 中；正文通常不要再重复一级标题，除非正文是在记录一份原始文档或完整规则文本。
- front matter 后第一段会作为首页摘要来源，应能独立概括文章主题；摘要后用 `---` 分隔正文，这是当前仓库常见格式。
- 中文文章保持 UTF-8 编码，正文标题从 `##` 开始组织层级。
- 每篇文章使用一到两个分类；分类只使用 `AI`、`开发工具`、`网络与代理`、`浏览器`、`体育技术`。调整白名单时必须同步更新 `test/content_health_test.rb`。
- `tags` 使用英文小写短标签，优先 4-6 个；避免大小写、单复数或其他同义变体，首页最多展示前 5 个标签。已知别名以 `test/content_health_test.rb` 的 `FORBIDDEN_TAG_ALIASES` 为准，例如统一使用 `agent`，不使用 `agents`。
- 新增文章必须检查是否属于 `_data/series.yml` 中的既有专题；如果属于，应在 front matter 添加 `series` 和对应 `series_order`，不属于时才明确不加专题。
- 公开文章必须脱敏真实密钥、Token、订阅、控制接口地址、个人路径、真实节点名、机场信息和剩余流量等敏感信息，使用占位符或匿名代号。
- 公开文章涉及赔率页、预测市场、平台入口、工具市场等内容时，默认使用中性、方法导向措辞，避免像广告、导流或 referral；具体入口如果不是正文重点，优先放在技能仓库或项目文档中。
- 命令和配置代码块尽量标注语言，例如 `bash`、`zsh`、`powershell`、`yaml`；提示词、输出或纯文本内容使用 `text`。
- 生成 Prompt 类文章时，建议包含适用场景、设计思路、完整提示词、使用建议和输出验收标准；完整提示词使用 `text` 代码块。

## 时效性内容与证据边界

- 故障文章必须区分可观察事实、合理推断和仍未确认的根因。某个启动参数、配置或缓存操作改变了现象，只能证明两者相关，不能据此断言根因。
- 无法在当前硬件、系统或产品版本中重新复现时，应明确写成“历史实测 workaround”“临时规避方式”或“可能相关”，不得升级为“官方修复”“根因已确认”或适用于所有环境的结论。
- 核验快速变化的工具文章时，优先使用官方文档、官方仓库、release 和 issue，并注明核验日期；“issue 仍为 open”只证明该 issue 的当前状态，不证明正文中的 workaround 得到官方认可。

## SEO 与标题

- 文章标题应兼顾可读性和 SEO：优先包含核心搜索词、具体工具/平台、问题场景或解决结果，避免过泛标题如“配置指南”“全记录”单独出现。
- 标题应与正文当前状态一致；如果正文说明旧方案已失效或已有新方案，标题也应体现“失效后的方案”“替代方案”“修复方式”等，避免给读者错误预期。
- 新写或修改文章标题时，使用“修复”必须有当前环境中的成功验证证据；如果只是历史方案、第三方 workaround 或当前无法复测，应优先使用“临时规避”“排查记录”“替代方案”或“待复核方案”。
- SEO 标题优化只改 front matter 的 `title` 时，通常不添加 `updated`；只有正文经过实质更新时才添加 `updated: YYYY-MM-DD`。

## 验证

- 纯文章内容或 front matter 小改，先做轻量检查：front matter 完整、`date` 不在未来、文件名格式正确、公开内容已脱敏；用户明确要求或改动风险较高时，再运行构建。
- 新增文章默认运行完整测试，除非用户明确要求跳过。
- 修改模板、样式、插件、站点配置、Liquid 逻辑、页脚、联系入口、评论、导航、搜索或分页等站点公共行为时，必须运行完整测试。
- 修改文章的 `status`、`verified`、`categories`、`tags`、`series`，或者更新对外声明“当前可用”的命令、版本和配置时，必须运行完整测试；普通措辞、错别字和不影响元数据的局部修订可以只做轻量检查。
- 新增文章可能改变首页分页顺序；测试不要假设某篇文章永远位于首页第一页，应优先断言功能在对应分页或站点产物中存在。
- 测试分组、专题、状态区块或首页模块时，必须把断言限定在目标容器或相邻结构标记之间；不要只断言整页包含某段文字或链接，因为同一内容可能出现在其他模块并造成假通过。
- 状态页测试应分别验证文章属于正确的 `status-section`，并至少包含一个反向断言，确认文章不会出现在错误状态区块。
- 修改 `_config.yml` 的 `exclude`、GitHub Actions、公共页面、数据文件或内部工具目录时，要确认维护脚本、测试、规划文档和本地配置不会发布到 `_site`，并同步更新相关测试。
- 本地预览必须使用仓库 toolchain：Windows 运行 `.\bin\serve.ps1`，macOS / Linux 运行 `bash bin/serve`；只有排查入口脚本或 Bundler 本身时才直接运行裸 `bundle exec jekyll serve`。
- 若构建失败，优先检查 Ruby 版本、Bundler 依赖和 `_config.yml` 配置。
- 完整交付至少运行项目测试入口、`git diff --check` 和 `git status --short --branch`，并确认 `_site` 等构建产物未进入提交范围。

### Windows / PowerShell 验证

- Windows 环境优先使用 PowerShell 脚本运行完整测试：

```powershell
.\bin\test.ps1
```

- `bin\test.ps1` 等价执行：

```powershell
bundle exec jekyll build
bundle exec ruby test/site_features_test.rb
bundle exec ruby test/content_health_test.rb
```

- 不假设 Windows 环境可用 `bash`；在 Windows 一律使用 `.\bin\test.ps1`，不要拆开运行裸 `bundle exec` 命令绕过 toolchain 入口。

### macOS / Linux 验证

- 先确保 `.ruby-version` 指定的 Ruby 已由版本管理器或包管理器选中，再运行 `bash bin/test`。
- 非标准 Ruby 路径只在当前 shell 设置 `ONLYDREAMS_RUBY`；不要把项目 Ruby 路径写入全局 shell 配置。
