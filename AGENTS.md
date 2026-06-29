# 仓库协作指南

本仓库是一个 Jekyll 静态博客站点。

## 开发环境

- Ruby 版本以 `.ruby-version` 为准。
- 使用 Bundler 管理依赖。
- 项目依赖默认安装到本地目录，避免污染全局 Ruby 环境。

## 常用命令

在仓库根目录执行：

```powershell
bundle install
bundle exec jekyll build
bundle exec jekyll serve
.\bin\test.ps1
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
- `status` 至少包含 `label`、`verified`、`environment` 和 `risk`；`label` 只使用 `当前可用`、`待复核`、`已失效`；`当前可用` 的 `verified` 使用 `YYYY-MM-DD`。
- `date` 必须早于当前实际构建时间，禁止写未来时间；不确定时使用当前时间向前取整或提前 5-10 分钟，避免 Jekyll 将文章当作未来文章跳过。
- 文章标题放在 front matter 的 `title` 中；正文通常不要再重复一级标题，除非正文是在记录一份原始文档或完整规则文本。
- front matter 后第一段会作为首页摘要来源，应能独立概括文章主题；摘要后用 `---` 分隔正文，这是当前仓库常见格式。
- 中文文章保持 UTF-8 编码，正文标题从 `##` 开始组织层级。
- `categories` 优先复用站内已有分类名，技术名词和产品名保持既有大小写，避免新增大小写变体；中文主题可使用中文分类。
- `tags` 使用英文小写短标签，优先 4-6 个；避免同义重复，首页最多展示前 5 个标签。
- 公开文章必须脱敏真实密钥、Token、订阅、控制接口地址、个人路径、真实节点名、机场信息和剩余流量等敏感信息，使用占位符或匿名代号。
- 公开文章涉及赔率页、预测市场、平台入口、工具市场等内容时，默认使用中性、方法导向措辞，避免像广告、导流或 referral；具体入口如果不是正文重点，优先放在技能仓库或项目文档中。
- 命令和配置代码块尽量标注语言，例如 `bash`、`zsh`、`powershell`、`yaml`；提示词、输出或纯文本内容使用 `text`。
- 生成 Prompt 类文章时，建议包含适用场景、设计思路、完整提示词、使用建议和输出验收标准；完整提示词使用 `text` 代码块。

## SEO 与标题

- 文章标题应兼顾可读性和 SEO：优先包含核心搜索词、具体工具/平台、问题场景或解决结果，避免过泛标题如“配置指南”“全记录”单独出现。
- 标题应与正文当前状态一致；如果正文说明旧方案已失效或已有新方案，标题也应体现“失效后的方案”“替代方案”“修复方式”等，避免给读者错误预期。
- SEO 标题优化只改 front matter 的 `title` 时，通常不添加 `updated`；只有正文经过实质更新时才添加 `updated: YYYY-MM-DD`。

## 验证

- 纯文章内容或 front matter 小改，先做轻量检查：front matter 完整、`date` 不在未来、文件名格式正确、公开内容已脱敏；用户明确要求或改动风险较高时，再运行构建。
- 新增文章默认运行完整测试，除非用户明确要求跳过。
- 修改模板、样式、插件、站点配置、Liquid 逻辑、页脚、联系入口、评论、导航、搜索或分页等站点公共行为时，必须运行完整测试。
- 新增文章可能改变首页分页顺序；测试不要假设某篇文章永远位于首页第一页，应优先断言功能在对应分页或站点产物中存在。
- 修改 `_config.yml` 的 `exclude`、GitHub Actions、公共页面、数据文件或内部工具目录时，要确认维护脚本、测试、规划文档和本地配置不会发布到 `_site`，并同步更新相关测试。
- 本地预览：运行 `bundle exec jekyll serve` 后在浏览器查看输出地址。
- 若构建失败，优先检查 Ruby 版本、Bundler 依赖和 `_config.yml` 配置。

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

- 不假设 Windows 环境可用 `bash`；如果 `bash bin/test` 不可用，使用 `.\bin\test.ps1` 或拆开执行上面的 `bundle exec` 命令。

### macOS / Homebrew Ruby 验证

- 在 macOS 且使用 Homebrew Ruby 3.3 时，可清理代理环境变量后运行完整测试：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy PATH=/usr/local/opt/ruby@3.3/bin:$PATH ./bin/test
```
