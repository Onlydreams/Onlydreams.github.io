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

## 验证

- 内容或样式改动：运行 `bundle exec jekyll build`。
- 本地预览：运行 `bundle exec jekyll serve` 后在浏览器查看输出地址。
- 若构建失败，优先检查 Ruby 版本、Bundler 依赖和 `_config.yml` 配置。
