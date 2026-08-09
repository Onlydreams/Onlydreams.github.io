---
layout: post
title: "xiaohongshu-web-enhancer：小红书 Web 只看图文与无空洞标题过滤"
date: 2026-08-09 13:30:00 +0800
updated: 2026-08-09
categories: [浏览器]
tags: [xiaohongshu, tampermonkey, userscript, content-filter, open-source]
status:
  label: 当前可用
  verified: 2026-08-09
  environment: Windows / Edge、Chrome / Tampermonkey / xiaohongshu-web-enhancer 0.2.1
  risk: 0.2.1 已修复并在 Edge + Tampermonkey 复测详情遮罩背景与关闭恢复；既有 Edge 深度矩阵、Chrome 核心矩阵和 Performance Trace 继续有效。Firefox、Violentmonkey 尚未验收，小红书 DOM 或瀑布流实现变化后仍可能需要重新适配。
---

`xiaohongshu-web-enhancer` 是一个轻量、无第三方依赖的小红书 Web 端 Userscript：进入页面后自动尝试开启“只看图文”，也可以按笔记标题关键词过滤首页信息流。它不删除或移动网站卡片，不调用小红书接口，不向平台提交“不感兴趣”，而是在浏览器本地完成匹配、布局压实和恢复。

---

## 为什么要做这个脚本

我在小红书 Web 端最常遇到两个问题：

1. 每次浏览器硬刷新后，都要重新点击右下角“只看图文”；
2. 想避开某类标题时，只能逐条略过，网页本身没有简单的本地关键词过滤入口。

第一个问题看起来只是自动点击，但脚本不能持续强制状态。用户手动取消后，本页就应该尊重这次选择；点击小红书右下角的原生刷新也不能再次替用户开启。只有浏览器硬刷新创建了新文档，脚本才重新尝试一次。

第二个问题真正麻烦的不是关键词匹配，而是过滤后的瀑布流。项目最初讨论 MVP 时，我也考虑过直接给命中卡片设置 `display: none`，再触发一次 `resize`。真实页面实验很快否定了这个思路：卡片使用绝对定位和内联 `transform`，容器高度也由网站计算，单独隐藏一张卡片只会留下明显空洞，网站并不会可靠地替脚本重新排版。

项目地址：[Onlydreams/xiaohongshu-web-enhancer](https://github.com/Onlydreams/xiaohongshu-web-enhancer)

项目最初只为“自动只看图文”建立，因此选择了单文件 Userscript 加 Node 内置测试的最小结构，没有打包器、框架和第三方运行时依赖。仓库使用 `xiaohongshu-web-enhancer` 而不是更窄的 `xiaohongshu-userscript`，是为了描述“增强小红书 Web 端”这个长期边界，而不是把项目永久限制在某一种脚本管理器上。

## 当前提供的两个功能

### 自动只看图文

脚本在页面启动后等待右下角筛选控件出现，最多等待 15 秒：

- 控件可用且尚未开启时，每个文档最多自动点击一次；
- 已处于 `loading` 或选中状态时不点击；
- 首次筛选期间可以短暂隐藏信息流，但 6 秒后必须先恢复页面，不能一直空白等待；
- 用户手动取消后，本页不再自动恢复；
- 页面原生刷新保留用户取消状态，浏览器硬刷新后才重新尝试；
- 向下滚动时让位于网站原生“回到顶部”按钮，回到顶部后再显示图文按钮。

### 首页标题关键词屏蔽

标题过滤只作用于 `/explore` 及其频道参数，只读取笔记标题，不匹配作者、正文、点赞数或其他字段。关键词支持中文、英文、Emoji 和不区分大小写的子串匹配。

首次安装时词表为空，不会自动过滤。打开 Tampermonkey 菜单，可以看到以下状态：

- `标题关键词屏蔽：未配置`
- `标题关键词屏蔽：已开启（N 个词）`
- `标题关键词屏蔽：已关闭（已保存 N 个词）`

通过“编辑标题屏蔽词”按 `关键词A|关键词B|关键词C` 的格式保存即可。菜单只显示规范化、去空和去重后的数量，不暴露具体词表；关键词保存在 Userscript 管理器的本地存储中，不写入页面 DOM，也不通过网络发送。

## 安装与使用

当前公开版本为 `0.2.1`，保持单文件发布，不需要构建：

1. 安装 Tampermonkey；
2. 打开并审查 [`xiaohongshu-enhance.user.js`](https://github.com/Onlydreams/xiaohongshu-web-enhancer/blob/main/xiaohongshu-enhance.user.js)；
3. 通过 [Raw 文件](https://raw.githubusercontent.com/Onlydreams/xiaohongshu-web-enhancer/main/xiaohongshu-enhance.user.js) 安装，或在 Tampermonkey 中新建脚本后完整粘贴源码；
4. 打开或刷新 `https://www.xiaohongshu.com/explore`；
5. 如需标题过滤，在 Tampermonkey 菜单中编辑关键词。

如果刷新后脚本完全没有运行，再检查 Chrome 扩展详情中的“允许用户脚本”和 Tampermonkey 的网站访问权限，确认 `https://www.xiaohongshu.com/*` 已获授权。不同浏览器或扩展版本的设置入口可能不同；脚本正常生效时无需额外改动。

Tampermonkey 的 [`GM_registerMenuCommand` 与本地存储 API](https://www.tampermonkey.net/documentation.php?locale=zh) 用于菜单和配置；脚本元数据没有手工加入由分发平台管理的 `@updateURL` 或 `@downloadURL`。手工粘贴安装的用户升级时需要自行覆盖旧源码，并确认脚本头部 `@version` 已更新。

脚本头部同时维护默认、中英文名称和功能描述，并声明 `@author`、`@homepageURL`、`@supportURL`、`@license MIT` 与 `@noframes`。这些字段不是装饰：名称与 namespace 决定脚本身份，描述需要与 README 的用户可见功能同步，`@noframes` 则避免脚本在匹配到的小红书子框架中重复运行。普通 GitHub 开发提交不会机械提升版本；进入 Greasy Fork 正式发布时，只要脚本代码或元数据变化，就必须提升 `@version`。

## 自动只看图文：从能点击到尊重原站交互

### 点击目标、首屏时序与一次性状态

第一版脚本曾经出现过一种很典型的“源码执行了，功能却没生效”：代码点击的是外层 `#image-note-filter-el`，Node 模拟测试也把外层元素设成可点击，因此测试全部通过；真实页面刷新后等待 4.5 秒，状态却仍是 `imgNote / 只看图文`。浏览器对照实验确认，当前小红书把事件绑定在内部 `.btn-wrapper` 上，点击外层没有效果，点击内部按钮才会进入 `imgNoteSelect / 取消只看图文`。现在脚本会同时用图标和提示文字判断状态，并且只点击经过真实页面验证的内部目标。

开发初期在当时页面完成的三次真实刷新还记录了首屏时序：`html/body` 约在 0.65 秒出现，信息流和首条笔记约在 2.12 秒出现，筛选按钮约在 2.98 秒出现，约 3.42 秒进入 `loading`，约 4.20 秒才确认选中。这组历史采样用于解释状态先后，不是当前所有网络和设备的固定性能指标。如果只在按钮出现后点击，用户会先看到约两秒未过滤的信息流。因此脚本改为 `document-start` 启动，在首屏信息流出现前安装局部可见性 gate，成功后以 120ms 淡入，并支持 `prefers-reduced-motion`；底层页面仍然正常渲染，只是避免把筛选前的中间状态直接展示出来。

这里把“信息流何时恢复可见”和“自动筛选何时停止等待”设计成了两个独立期限。6 秒只负责避免页面长时间不可见，15 秒负责接住较晚渲染的控件；不能因为页面发生 `pageshow` 或 `popstate` 就把期限不断向后延长。

一次性状态也是从真实缺陷中得到的。旧逻辑在用户手动取消后仍持续观察和轮询，浏览器记录到筛选先进入 `loading`，约 2.6 秒后又被脚本重新拉回选中态。后续独立代码评审又发现，原来的“3 秒冷却”并不等于“本页只尝试一次”，6 秒可见性兜底还错误地停止了全部自动化。最终状态机拆成“尚未尝试、已经尝试仅观察、已经完成并清理”，首次点击前立即锁定本页尝试状态；observer、interval、timeout 和页面事件也都有对应清理路径。

### 返回顶部按钮为什么会闪一下

滚动交互经历了两轮修复。第一轮真实页面检查发现，筛选处于选中态时，小红书会把“取消只看图文”和 `.back-top.active` 同时保留在同一个 `.floating-btn-sets` 容器中。脚本因此只在原生返回顶部按钮激活时隐藏图文按钮，回到顶部后条件自动失效，不接管滚动事件。

但这仍留下一个很短的跳动窗口。在当时视口完成的逐段滚动采样显示，`scrollY = 260` 附近的 `.back-top` 已经挂载且 `display: flex`，只是 `opacity: 0`，它会先占据 40px 高度，把图文按钮向上顶一格；到 `scrollY = 290` 左右才获得 `active`，图文按钮随后隐藏。用户看到的“闪一下”实际是这个透明原生按钮提前参与布局，而不是脚本反复点击筛选；这里的坐标只用于还原诊断过程，最终实现没有写死滚动阈值。

最终 CSS 把两个状态分开处理：

```css
.floating-btn-sets .back-top:not(.active) {
  display: none !important;
}

.floating-btn-sets:has(.back-top.active) #image-note-filter-el {
  display: none !important;
}
```

未激活的返回顶部按钮不再透明占位；激活后，它在原位置替换图文按钮。这个修复保留了小红书原有交互，也避免新增滚动监听和阈值猜测。

到这里，“自动只看图文”解决的是如何替用户完成一次操作，同时不破坏原站状态和滚动交互。第二项“标题关键词屏蔽”看起来只是字符串匹配，真正困难的却是另一件事：隐藏命中卡片以后，怎样让小红书的瀑布流继续连续排列，而不是留下空洞。

## 标题过滤：从关键词匹配到无空洞布局

### 瀑布流为什么不能简单重排

阶段 0 在真实页面采集了 2～5 列布局样本。实验发现，小红书无限滚动时会保留一个不断变化的连接窗口，现存卡片的原生坐标不一定从 `y = 0` 开始。如果把当前 58 张卡片当作一批新数据，从顶部重新执行最短列布局，最大坐标误差可达到约 `13151px`。

最终实现不猜测小红书的完整瀑布流算法，也不写死列数和响应式断点，而是从当前原生几何中反推出列：

1. 读取每张卡片已有的 `x`、`y`、宽度和高度；
2. 根据原生 `x` 坐标识别当前 2～5 列；
3. 保留每张卡片所属列和原生 `x`；
4. 只在同一列内累计扣除被过滤卡片的高度与间距；
5. 用脚本专属 CSS 自定义属性提交新坐标。

这样既能填掉标题过滤产生的空洞，也不会把虚拟化后仍连接在 DOM 中的卡片误当成从页面顶部开始的新列表。

脚本不会删除、移动或重新创建 Vue 管理的卡片，也不覆盖网站原始 `transform`。根节点、卡片和布局写入使用专属 `data-*` 所有权标记；文档 active class、注入样式与各类监听由控制器生命周期统一清理。关闭功能、清空词表、离开首页或替换信息流根时，只撤销脚本自己的状态，网站和其他扩展写入的样式保持不动。

### 从“整根闪白”反推状态交接

自动化测试全部通过后，真实 Performance Trace 仍连续暴露过三类完整信息流空白：

- 已接管的同一根在重新测量时，旧布局先被撤销，新布局下一帧才提交；
- SPA 返回或根重新连接时，新根既没有可用提交，也没有保留网站布局；
- 即使撤销和重建发生在同一个 JavaScript 工作帧，强制样式读取也可能捕获中间状态并触发可见绘制。

这促成了实现中最重要的一条约束：页面已经展示过以后，脚本布局和网站布局之间必须始终至少有一个可见 gate。

- 接管前先完成整套布局，再退出 `bypass`；
- 放弃接管时先进入 `bypass`，再撤销 `ready`；
- 重新测量时先让网站布局接住页面，再读取原生几何；
- 提交恢复时先写回 `ready`，最后才撤掉 `bypass`。

`ready` 表示一份完整、可展示的脚本布局，`bypass` 表示暂时交还给网站原生布局。稳定状态下两者互斥，交接期间可以短暂同时存在，但在已经展示过的页面上不能同时缺失。

第五轮 Trace 复测抽取了 147 张截图，覆盖桌面多列、窄屏两列和恢复多列，未再出现整根空白、空洞或重叠。这类问题只靠 DOM 终态断言很难发现：测试可能看到“最后是对的”，用户却会看到中间一帧整页消失。

### 页面变化时，宁可恢复原站布局

脚本只接管已经验证的几何结构。遇到以下情况会立即 fail-open，恢复网站排版，而不是带着错误假设继续计算：

- 根进入 `.layout-frozen` 或 `.static-layout`；
- 出现未经验证的直接子节点；
- 卡片尺寸、列样本或二维坐标不足以形成可信快照；
- transaction 超时、根已断开或 generation 已过期；
- 测量、计算或 DOM 提交任一环节抛出异常。

恢复后，脚本在后台等待连续两份稳定快照，再决定是否重新接管。没有外部变化时，完整恢复验证最多执行 5 次指数退避，避免在永久不兼容的页面结构上持续做高成本工作；根 class、直接结构、宽度或配置真正变化时才重置预算。

MutationObserver 负责发现新增卡片和结构变化，实际布局工作合并到 `requestAnimationFrame`，每个根每帧最多一次。根替换时 generation 会递增，旧根迟到的 rAF、watchdog、异常处理和 `finally` 都不能再修改当前根。这些约束不仅处理正常的无限滚动，也覆盖频道切换、SPA 详情返回、原生刷新和无 URL 信号的根替换。

### 详情页不是另一张独立页面

`0.2.0` 发布后又发现了一处与原站交互有关的回归：从首页点击笔记后，详情内容正常打开，但遮罩后的主信息流完全消失；只有关闭详情、返回首页后才重新出现。

Chrome 真实页面复现给出了完整状态链：

- 点击前路径为 `/explore`，信息流根 `ready=true / visibility=visible`；
- 打开详情后路径变为 `/explore/<note-id>`，`.note-detail-mask` 正常存在，`#exploreFeeds` 也仍连接在 DOM 中；
- 脚本已经撤销根的 `ready`、`bypass` 和卡片所有权，却没有撤销 `<html>` 上的标题过滤 active class；
- 预隐藏 CSS 因而命中这个既无 `ready`、也无 `bypass` 的原生根，将背景设为 `visibility:hidden`；
- 关闭详情返回 `/explore` 后，脚本重新提交布局，信息流才恢复。

错误来自一个看似合理、实际不成立的假设：离开精确的 `/explore` 就不会再有信息流根。小红书详情不是替换首页，而是在同一份首页 DOM 上叠加遮罩；背景信息流本身也是原生交互的一部分。

更值得警惕的是，原有测试把“非目标路由仍保留 active class”写成了正确预期，因此测试全绿反而固化了错误模型。`0.2.1` 把 active 严格限定在精确 `/explore`：离开时先撤 active，再恢复根和卡片；返回首页后才重新添加 active，并通过既有 `bypass/ready` 交接重新接管。

独立审查发现，第一版修复测试仍使用泛化的 `/detail/1`，没有采用小红书真实的 `/explore/<note-id>`；技术方案也曾在新版尚未装入 Tampermonkey 时提前勾选浏览器验收。两项问题均在发布前修正：测试改用真实路由形态，版本清单同步为 `0.2.1`，并且只在新版保存到 Tampermonkey 后更新验收状态。

最终 Edge + Tampermonkey 复测同时取得了用户手工结果和页面 DOM 证据：详情打开后的即时、100ms、400ms 三个采样均为 `active=false`，信息流根始终 `visibility:visible / display:block / opacity:1`，脚本所有权为 0；关闭遮罩后约 500ms 返回 `/explore`，32 张卡片重新进入 ready/owned，未记录到脚本 warning 或 error。至此“首页打开详情、背景保持可见、关闭详情后重新接管”的闭环完成。

## 性能验证不是只跑一个计时器

项目把证据拆成三层：

1. Node 内置测试验证关键词、列识别、可逆 transaction、生命周期、菜单状态和故障恢复；
2. 确定性 benchmark 对 32、200、500 张卡片执行与正式脚本相同的匹配和布局算法；
3. Edge、Chrome + Tampermonkey 真实页面验证实际 DOM、绘制、缩放、无限滚动和 SPA 生命周期。

当前 `npm run check` 共 69 项通过：16 项为原有“自动只看图文”回归，1 项验证标题过滤预门控与既有启动流程的跨模块集成，52 项为标题过滤专项。合成门禁结果为：

| 场景 | 实测 | 门禁 |
| --- | ---: | ---: |
| 50 个标题匹配场景最大 p95 | `0.066ms` | `< 2ms` |
| 200 卡完整 transaction p95 | `1.271ms` | `≤ 16.7ms` |
| 500 卡完整 transaction max | `2.978ms` | `≤ 50ms` |

Edge 主负载 Trace 中，87 个布局工作帧的 Userscript 回调最大为 `4.946ms`，之后的下一次 `PrePaint` 87/87 都在 `16.7ms` 内。Trace 确实包含页面 long task，但脚本自身没有超过 `4.946ms` 的回调，因此不能把页面的全部长任务归因给这个 Userscript。

这些数字证明的是当前样本和环境没有明显算法退化，不代表所有设备上的真实绘制成本都相同。benchmark 也不能替代浏览器 Trace，这正是项目保留两层性能证据的原因。

## 当前验证边界

截至 2026-08-09，当前源码已完成：

- Edge + Tampermonkey 深度矩阵，包括 2～5 列、80%/100%/125% 缩放往返、无限滚动、频道切换、SPA 返回、原生刷新、硬刷新和 Performance Trace；
- Edge + Tampermonkey `0.2.1` 详情遮罩回归复测，包括打开后三段采样保持原生背景可见、关闭后重新进入 ready/owned，以及脚本 warning/error 检查；
- Chrome + Tampermonkey 核心矩阵，包括标题唯一命中、响应式 2～5 列、关闭/重启/清空、两个功能独立运行，以及动态不稳定布局、无 URL 信号根替换和旧根 rAF 竞态故障注入；
- 69 项源码测试与 32/200/500 卡确定性性能门禁。

`0.2.1` 只改变标题过滤离开和返回精确 `/explore` 时的 active 路由门控；既有矩阵提供原功能范围证据，详情遮罩复测提供本次修复的增量证据，二者没有混写成同一层验收。

Firefox 与 Violentmonkey 尚未纳入兼容性验收，因此不应据此视为已确认支持。标题过滤也依赖当前已验证的 `#exploreFeeds.feeds-container`、直接 `section.note-item[data-note-id]` 卡片和标题链接结构；小红书修改 DOM、布局 class 或虚拟化策略后，脚本应该先 fail-open，但仍可能需要更新 DOM 适配逻辑或选择器。

第三方网站 DOM 永远是会变化的外部契约，而测试也可能把错误假设写成契约。当前核心行为与详情背景修复均已在声明环境中完成对应层级复测，因此文章恢复为“当前可用”；这仍不代表未来网站改版后无需重新验证。

## 源码、反馈与许可证

- 项目仓库：[Onlydreams/xiaohongshu-web-enhancer](https://github.com/Onlydreams/xiaohongshu-web-enhancer)
- 当前脚本：[xiaohongshu-enhance.user.js](https://github.com/Onlydreams/xiaohongshu-web-enhancer/blob/main/xiaohongshu-enhance.user.js)
- 问题反馈：[GitHub Issues](https://github.com/Onlydreams/xiaohongshu-web-enhancer/issues)
- Tampermonkey 安装说明：[官方 FAQ](https://www.tampermonkey.net/faq.php?locale=zh&q=Q102)

项目采用 MIT License。它是本地页面增强工具，与小红书官方没有隶属或代表关系。反馈兼容问题时，最有价值的信息不是一句“失效了”，而是浏览器、Userscript 管理器、页面路由、进入路径、当前列数、是否经过 SPA 跳转，以及问题发生时根是否带有 `.layout-frozen`、`ready` 或 `bypass` 状态。
