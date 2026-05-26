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
```

修改文章、模板、插件或站点配置后，至少执行一次：

```powershell
bundle exec jekyll build
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
- 不要提交本地缓存、依赖目录、构建产物、日志、环境变量文件或编辑器私有配置。

## 博客文章生成约定

- 新文章放在 `_posts/`，文件名格式为 `YYYY-MM-DD-slug.md`。
- 必须使用 YAML front matter，至少包含 `layout: post`、`title`、`date`、`categories` 和 `tags`；只有文章经过实质更新时才添加 `updated: YYYY-MM-DD`。
- `date` 必须早于当前实际构建时间，禁止写未来时间；不确定时使用当前时间向前取整或提前 5-10 分钟，避免 Jekyll 将文章当作未来文章跳过。
- 文章标题放在 front matter 的 `title` 中；正文通常不要再重复一级标题，除非正文是在记录一份原始文档或完整规则文本。
- front matter 后第一段会作为首页摘要来源，应能独立概括文章主题；摘要后用 `---` 分隔正文，这是当前仓库常见格式。
- 中文文章保持 UTF-8 编码，正文标题从 `##` 开始组织层级。
- `categories` 优先复用站内已有分类名，技术名词和产品名保持既有大小写，避免新增大小写变体；中文主题可使用中文分类。
- `tags` 使用英文小写短标签，优先 4-6 个；避免同义重复，首页最多展示前 5 个标签。
- 公开文章必须脱敏真实密钥、Token、订阅、控制接口地址、个人路径、真实节点名、机场信息和剩余流量等敏感信息，使用占位符或匿名代号。
- 命令和配置代码块尽量标注语言，例如 `bash`、`zsh`、`powershell`、`yaml`；提示词、输出或纯文本内容使用 `text`。
- 纯文章内容或 front matter 小改，先做轻量检查：front matter 完整、`date` 不在未来、文件名格式正确、公开内容已脱敏；用户明确要求时再运行构建。
- 新增文章默认运行 `./bin/test` 验证，除非用户明确要求跳过构建。
- 修改模板、样式、插件、站点配置或 Liquid 逻辑时，必须运行 `./bin/test`。
- 本机验证建议使用 Homebrew Ruby 3.3 路径，并清理代理环境变量：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy PATH=/usr/local/opt/ruby@3.3/bin:$PATH ./bin/test
```

## 验证

- 内容或样式改动：运行 `bundle exec jekyll build`。
- 本地预览：运行 `bundle exec jekyll serve` 后在浏览器查看输出地址。
- 若构建失败，优先检查 Ruby 版本、Bundler 依赖和 `_config.yml` 配置。
