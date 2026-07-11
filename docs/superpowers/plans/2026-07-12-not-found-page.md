# 404 恢复页实现计划

> **执行方式：** 按失败测试、最小实现、完整验证的顺序执行；每个任务完成后更新 checkbox。

**目标：** 新增一个可恢复浏览路径的静态 404 页面，保持现有博客的编辑式视觉和无 JavaScript 依赖。

**架构：** `404.html` 以 Jekyll 的 `default` layout 生成根目录错误页；页面只包含静态导航链接。样式放在既有 `_sass/theme/_taxonomy-search.scss`，测试读取构建产物和 SCSS 源文件。

**技术栈：** Jekyll 4、Liquid、SCSS、Minitest、PowerShell 测试入口 `./bin/test.ps1`。

---

## 文件结构

- Create: `404.html`
- Create: `docs/superpowers/specs/2026-07-12-not-found-page-design.md`
- Create: `docs/superpowers/plans/2026-07-12-not-found-page.md`
- Modify: `_sass/theme/_taxonomy-search.scss`
- Modify: `test/site_features_test.rb`

### Task 1: 写失败测试

- [x] 在 `test/site_features_test.rb` 中添加 `test_not_found_page_offers_static_recovery_paths`。
- [x] 断言 `_site/404.html`、robots 元数据、四个恢复链接和三个 SCSS 选择器。
- [x] 运行 `./bin/test.ps1`，确认在缺少页面时失败（`Errno::ENOENT: _site/404.html`）。

### Task 2: 实现页面和样式

- [x] 新增 `404.html`，使用 `permalink: /404.html`、`noindex, follow` 和四个恢复入口。
- [x] 在 `_sass/theme/_taxonomy-search.scss` 添加窄屏可用的 `.not-found-*` 样式。
- [x] 运行 `./bin/test.ps1`，确认测试转绿。

### Task 3: 最终验证

- [x] 运行 `git diff --check`，确认没有 whitespace error。
- [x] 更新本计划的 checkbox，记录实际测试结果：`46 runs, 588 assertions` 与 `6 runs, 308 assertions`，均为 0 failures。
