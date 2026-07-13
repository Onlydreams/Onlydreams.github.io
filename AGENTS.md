# 仓库协作指南

本仓库是 Onlydreams 个人维护的 Jekyll 静态技术博客，公开站点为 `https://www.dayjia.com`。修改应服务于内容可信度、阅读体验和长期可维护性，不按多人团队项目扩张流程或文档。

## 文档职责与事实来源

- `README.md` 只保留项目定位、线上地址和最短本地开发入口，不放长篇环境安装、故障排查、文章规范或内部实现说明。
- `AGENTS.md` 是本仓库开发、内容、验证和交付规范的权威来源；未经用户明确指令不要修改它。
- `bin/setup*`、`bin/test*`、`bin/serve*` 和 `bin/preflight*` 是工具链行为的可执行真相；文档不得复制容易漂移的内部实现。
- `test/site_features_test.rb` 与 `test/content_health_test.rb` 是站点行为和内容元数据的可执行契约。规则变化时同步更新规范、实现和对应测试。
- 工具链或测试与说明冲突时，以当前脚本和测试为准，并在本次改动中修正文档。

## 开发环境与工具链

- Ruby 必须与 `.ruby-version` 完全一致；Bundler 和 gems 以 `Gemfile.lock` 为准，项目依赖安装到忽略的 `vendor/bundle`。
- 初始化脚本负责准备仓库依赖，不替代 Ruby 运行时安装。Windows 优先安装匹配版本的 RubyInstaller Ruby+Devkit x64，并完成所需的 MSYS2/Devkit 初始化；macOS / Linux 使用版本管理器或包管理器选择精确版本。
- 日常操作必须使用仓库 toolchain 入口；不要直接运行裸 `bundle` 或 `bundle exec`，除非正在排查 Bundler 或入口脚本本身。
- 非标准 Ruby 路径只在当前 shell 设置 `ONLYDREAMS_RUBY`；不要把项目 Ruby 路径写入全局 shell 配置。
- 不要持久设置 `BUNDLE_PATH`、`GEM_HOME`、`GEM_PATH` 或 `RUBYOPT`；入口脚本会在当前进程隔离外部环境，避免不同 Ruby 版本互相污染。
- 出现 `expected Ruby ...` 时，安装或激活 `.ruby-version` 指定版本；出现 `Bundler ... is unavailable` 时，检查该 Ruby 的安装完整性，不要借用其他 Ruby 的全局 gems。

### macOS / Linux

```bash
bash bin/setup
bash bin/test
bash bin/serve
```

### Windows PowerShell

```powershell
.\bin\setup.ps1
.\bin\test.ps1
.\bin\serve.ps1
```

- 不假设 Windows 可用 `bash`；Windows 一律使用 PowerShell 入口。
- `setup` 用于首次或依赖变化后的初始化，`test` 执行完整验证，`serve` 启动本地预览。

## 仓库结构与改动边界

- `_posts/`：博客文章。
- `_layouts/`、`_includes/`、`_plugins/`：页面布局、复用模板和本地插件。
- `_data/`：专题等结构化站点数据。
- `assets/`、`_sass/`：静态资源和样式。
- `test/`：站点行为与内容健康检查。
- `bin/`：跨平台初始化、测试、预览和环境预检入口。
- `docs/superpowers/`：内部设计、规格和实施计划，不属于公开站点内容。
- `_site/`、`vendor/bundle/`：本地构建和依赖产物，不应提交。

- 站点内容以中文为主，Markdown 文件保持 UTF-8 编码。
- 修改保持小而聚焦；先理解现有页面、Liquid 数据流或脚本调用链，再在正确层级修改，避免无关重构。
- 改动 `_config.yml` 时检查 `exclude`、plugins、分页和 SEO 配置，确保维护脚本、测试、规划文档和本地配置不会发布到 `_site`。
- `docs/superpowers/specs/`、`docs/superpowers/plans/` 等内部文档默认使用简体中文，除非用户明确要求英文。
- 不提交本地缓存、依赖目录、构建产物、日志、环境变量文件或编辑器私有配置。

## 文章与元数据规范

- 新文章放在 `_posts/`，文件名格式为 `YYYY-MM-DD-slug.md`。
- 必须使用 YAML front matter，至少包含 `layout: post`、`title`、`date`、`categories`、`tags` 和 `status`；只有正文经过实质更新时才添加 `updated: YYYY-MM-DD`。
- `date` 必须早于实际构建时间；不确定时使用当前时间向前取整或提前 5-10 分钟，避免被 Jekyll 当作未来文章跳过。
- 标题只放在 front matter 的 `title` 中；正文通常不重复一级标题，正文标题从 `##` 开始。
- front matter 后第一段作为首页摘要，应能独立概括主题；摘要后用 `---` 分隔正文。
- 命令和配置代码块标注合适语言，例如 `bash`、`zsh`、`powershell`、`yaml`；提示词、输出或纯文本使用 `text`。
- Prompt 类文章建议包含适用场景、设计思路、完整提示词、使用建议和输出验收标准；完整提示词使用 `text` 代码块。

### 状态

- `status` 至少包含 `label`、`verified`、`environment` 和 `risk`；`label` 只使用 `当前可用`、`待复核`、`已失效`。
- `verified` 统一使用 `YYYY-MM-DD`，表示最近一次完成文中所声明核验范围的日期，不自动代表已完成端到端复测。
- `当前可用` 表示核心操作已在声明环境中验证；只确认了官方资料、项目能力、issue 状态或历史 workaround，但未完成当前环境复测时，使用 `待复核`，并在 `risk` 中写明尚未验证的部分；确认方案不可继续使用时标记为 `已失效`。

### 分类、标签与专题

- 每篇文章使用一到两个分类；分类只使用 `AI`、`开发工具`、`网络与代理`、`浏览器`、`体育技术`。调整白名单时同步更新 `test/content_health_test.rb`。
- `tags` 使用英文小写短标签，优先 4-6 个；避免大小写、单复数或其他同义变体，首页最多展示前 5 个标签。已知别名以 `FORBIDDEN_TAG_ALIASES` 为准，例如统一使用 `agent`，不使用 `agents`。
- 新增文章必须检查 `_data/series.yml`；属于既有专题时添加 `series` 和对应 `series_order`，不属于时不强行创建专题。

## 公开信息、证据与 SEO

- 公开文章必须脱敏真实密钥、Token、订阅、控制接口地址、个人路径、真实节点名、机场信息和剩余流量，使用占位符或匿名代号。
- 不把 GitHub `users.noreply.github.com` 地址作为公开联系邮箱；优先使用 GitHub、文章评论或其他已确认可用入口。只有确认域名邮箱完成收发配置后才公开展示。
- 涉及赔率页、预测市场、平台入口或工具市场时使用中性、方法导向措辞，避免广告、导流或 referral；非正文重点的具体入口优先放在对应项目文档。
- 故障文章必须区分可观察事实、合理推断和未确认根因。参数、配置或缓存操作改变现象只能证明相关，不能据此断言根因。
- 无法在当前硬件、系统或产品版本重新复现时，应写成“历史实测 workaround”“临时规避方式”或“可能相关”，不得升级为“官方修复”“根因已确认”或适用于所有环境的结论。
- 核验快速变化的工具文章时，优先使用官方文档、官方仓库、release 和 issue，并注明核验日期；“issue 仍为 open”只证明该 issue 的当前状态，不证明 workaround 得到官方认可。
- 标题兼顾可读性和 SEO，优先包含核心搜索词、具体工具、问题场景或结果，避免单独使用“配置指南”“全记录”等宽泛标题。
- 标题必须与正文状态一致。新写或修改标题时，使用“修复”必须有当前环境成功验证证据；历史方案、第三方 workaround 或无法复测的内容优先使用“临时规避”“排查记录”“替代方案”或“待复核方案”。
- 只优化 front matter 的 `title` 通常不添加 `updated`；只有正文实质更新才记录更新时间。

## 测试与交付

- 纯措辞、错别字或不影响元数据的文章小改可先做轻量检查：front matter 完整、日期不在未来、文件名正确、公开内容已脱敏。
- 新增文章，或修改 `status`、`verified`、`categories`、`tags`、`series`、对外声明“当前可用”的命令、版本和配置时，必须运行完整测试。
- 修改模板、样式、插件、站点配置、Liquid、公共页面、页脚、联系入口、评论、导航、搜索、分页、数据文件、GitHub Actions 或内部工具目录时，必须运行完整测试。
- 新增文章可能改变首页分页顺序；测试不要假设某篇文章永远位于首页第一页，应在对应分页或站点产物中断言。
- 测试分组、专题、状态区块或首页模块时，把断言限定在目标容器或相邻结构标记之间，不要只断言整页包含文字或链接。
- 状态页测试分别验证文章属于正确的 `status-section`，并至少包含一个反向断言，确认文章不会出现在错误状态区块。
- 若构建失败，先检查 Ruby 版本、Bundler、入口脚本和 `_config.yml`，再修改站点实现。
- 完整交付运行当前平台的 `bin/test` 入口、`git diff --check` 和 `git status --short --branch`，并确认 `_site`、`vendor/bundle` 等产物未进入提交范围。
- 涉及提交或推送时，先检查分支和工作树，只 stage 本次目标文件；只有用户明确要求后才 commit 或 push。
