# 404 恢复页设计

## 目标

为错误链接、历史 URL 和手动输入错误提供一个有用的静态恢复页，让读者能继续浏览或检索，而不是停留在浏览器默认错误页面。

## 范围

本次包含：

- 新增站点根目录的 `404.html`，供 GitHub Pages 等静态托管识别。
- 说明请求路径未找到，并提供首页、搜索、专题和索引入口。
- 添加与现有暖色编辑风格一致的轻量样式，兼容深色模式和窄屏。
- 在站点功能测试中覆盖生成结果、SEO robots 元数据、关键链接和样式选择器。

本次不包含：

- 客户端自动跳转、路由猜测或 JavaScript 监控。
- 将 404 页面加入主导航或 sitemap。
- 新增插件、依赖、图片或字体。
- 对所有旧链接建立 redirect 规则。

## 页面行为

页面 front matter 使用：

```yaml
---
layout: default
title: 页面未找到
permalink: /404.html
robots: noindex, follow
sitemap: false
---
```

页面输出应满足：

- 构建产物是 `_site/404.html`，不是目录形式的 `/404/index.html`。
- 使用一个 `h1` 明确表示页面未找到；不把 URL 原样插入 HTML，避免把不可信路径写回页面。
- 提供四个可访问的静态链接：`/`、`/search/`、`/series/`、`/archive/`。
- 通过 `robots: noindex, follow` 避免错误页被索引，同时让爬虫仍可沿站内链接继续发现内容。

## 视觉方向

采用“迷路但可恢复”的编辑式留白：小型橙色坐标标签、克制的大标题，以及一个明确的首页主操作。搜索、专题和索引作为主操作下方的轻量文本链接，不再使用四张等权卡片。它复用站点已有的 Lora/Poppins、暖橙强调色、暖灰背景和圆角边框；不引入插画、渐变或额外资源。

辅助链接在桌面端横向排列、窄屏时自然换行；键盘 focus 继续使用站点现有可见焦点样式。

## 测试与验收

扩展 `test/site_features_test.rb`，断言：

- `_site/404.html` 存在，包含 `页面未找到` 和 `404`。
- 页面输出 `noindex, follow` robots 元数据。
- 页面包含首页、搜索、专题和索引链接。
- SCSS 包含 `.not-found-page`、`.not-found-primary-action`、`.not-found-links` 和 `.not-found-link`。

验收命令：

```powershell
.\bin\test.ps1
git diff --check
```

两者均须通过，且不提交 `_site/`、缓存或依赖目录。
