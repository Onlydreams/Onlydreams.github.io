# 搜索增强与默认分享卡片实现计划

> **执行方式：** 先让测试失败，再完成最小静态实现；每项完成后更新 checkbox。

**目标：** 在现有 Jekyll 搜索页增加可链接的筛选和安全高亮，并为文章添加可被 SEO 插件读取的统一默认分享卡片。

**架构：** `search.json` 提供 800 字正文和状态字段；`search.md` 提供输入与筛选控件；`assets/js/search.js` 负责 URL 状态、筛选、渲染与 DOM 安全高亮；样式复用 `_taxonomy-search.scss`。默认 PNG 放在 `assets/images/`，`_config.yml` 通过 posts scope defaults 交给 `jekyll-seo-tag`。

## 文件结构

- Create: `docs/superpowers/specs/2026-07-12-search-and-share-card-design.md`
- Create: `docs/superpowers/plans/2026-07-12-search-and-share-card.md`
- Create: `assets/images/onlydreams-og-card.png`
- Modify: `search.md`
- Modify: `search.json`
- Modify: `assets/js/search.js`
- Modify: `_sass/theme/_taxonomy-search.scss`
- Modify: `_config.yml`
- Modify: `test/site_features_test.rb`

## 任务

### 1. 写失败测试

- [x] 扩展搜索页、索引、脚本和样式的功能约定测试。
- [x] 添加默认文章分享图的构建产物与配置测试。
- [x] 运行 `./bin/test.ps1`，确认新断言在实现前失败：缺少筛选控件，且 `_config.yml` 尚未定义 `defaults`。

### 2. 实现搜索增强

- [x] 在搜索页面加入分类、标签、状态筛选控件。
- [x] 扩展索引的正文范围和状态字段。
- [x] 实现 URL 参数读取/同步、组合筛选和安全命中高亮。
- [x] 为窄屏补充紧凑的筛选布局和高亮样式。

### 3. 实现默认分享卡片

- [x] 生成并保存 1200×630 默认 PNG 卡片。
- [x] 为 posts scope 添加可覆盖的默认 `image` 元数据。
- [x] 确认构建文章输出 OG/Twitter 图片、尺寸和替代文本。

### 4. 完整验证

- [x] 运行 `./bin/test.ps1`：48 runs, 646 assertions；6 runs, 308 assertions，均为 0 failures。收到代码审查意见后补充了搜索深链接、组合筛选、URL 同步和安全高亮的运行时 DOM 测试。
- [x] 运行 `git diff --check`。
- [x] 更新本计划的结果和 checkbox。
