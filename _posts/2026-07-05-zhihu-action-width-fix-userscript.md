---
layout: post
title: "知乎美化/知乎增强本地 Fix：修正操作栏与搜索页错位"
date: 2026-07-05 11:35:00 +0800
updated: 2026-07-15
categories: [浏览器]
tags: [zhihu, tampermonkey, userscript, css, fix]
status:
  label: 当前可用
  verified: 2026-07-15
  environment: Tampermonkey / Chrome、Edge / 知乎网页 / 知乎美化、知乎增强脚本叠加后
  risk: 只修改本地页面样式，不修改知乎数据；v0.8.0 已补充搜索结果页和 SPA 进入搜索页的回归覆盖，知乎页面 DOM 或原脚本样式更新后仍可能需要重新调整。
---

这是一个安装了“知乎美化”和“知乎增强”之后的本地 fix 版脚本，用来修正知乎推荐流、内容列表和搜索结果页里“赞同 / 评论 / 分享”操作栏的宽度与位置错位，并补齐首次进入搜索页时缺失的宽屏布局。脚本已经单独放到 GitHub 项目维护：[Onlydreams/zhihu-action-width-fix](https://github.com/Onlydreams/zhihu-action-width-fix)。

---

## 原脚本分别做什么

“知乎美化”和“知乎增强”解决的是两个不同方向的问题。

“知乎美化”主要改知乎网页的视觉层：压缩多余留白、调整卡片和正文区域、弱化干扰元素，让推荐流和回答页更像一个适合阅读的页面。

“知乎增强”更偏功能增强：通常会补充屏蔽、过滤、快捷操作、页面行为优化等能力，用来绕开知乎官方设置里不够细的控制项，比如推荐流里按关键词或内容特征做更细粒度处理。

这两个脚本本身都有用，但叠加之后会一起影响知乎卡片结构和操作栏样式。本文这个脚本只处理叠加后的本地 UI 偏差，不承担内容过滤、推荐屏蔽或页面功能增强。

## 问题现象

装完“知乎美化”和“知乎增强”后，知乎页面会出现几类布局问题：

- 推荐流普通卡片底部的“赞同 / 评论 / 分享”操作栏宽度和正文不一致。
- 页面底部的 fixed / sticky 操作栏比卡片更宽，或者左右位置偏移。
- 展开内容后，非 fixed 操作栏仍沿用旧位置，滚动出来时继续错位。
- 搜索结果页里，操作栏外层按外部卡片宽度对齐，但正文内容区更窄，导致左右错位。
- 搜索结果页存在嵌套操作行，子层 `.ContentItem-action` 可能重复继承外层宽度、内边距和下边距，导致按钮、评论和时间控件溢出或上下错位。
- 从推荐页通过顶部搜索框首次进入搜索页时，“知乎美化”的搜索页宽屏 CSS 可能没有重新注入，右侧信息栏仍然显示，刷新页面后才正常。

早期版本只用 CSS 强行改 `.ContentItem-actions` 宽度，或者把 fixed 浮动条单独处理。这个方向能修一部分场景，但在折叠、展开、底部 fixed、搜索结果页和 SPA 跳转之间容易互相打架。当前 v0.8.0 的处理方式是：保留少量常驻 CSS，同时用 JS 动态读取所在容器的真实 `left / width` 和正文缩进，再按不同页面结构校正操作栏。

## 脚本功能

这个本地 fix 脚本做六件事：

1. 只处理知乎页面里的 `.TopstoryItem`、`.List-item`、`.Card` 和搜索结果内容容器中的操作栏。
2. 每条操作栏都找到它所在的布局根节点，读取真实尺寸，再把操作栏宽度锁到对应范围内。
3. 通过正文元素计算按钮左右缩进，避免背景条对齐了但按钮整体偏移。
4. 搜索结果页优先使用 `.ContentItem` 作为测量根，避免被外层 `.List-item` 或 `.SearchResult-Card` 的宽度带偏。
5. 只把同时具有容器类和单项类的直接子元素识别为嵌套操作行，清理其重复继承的纵向样式，避免把普通评论按钮或时间控件扩成整行。
6. 常驻注入 `.SearchMain` 宽度和右栏隐藏规则，修复从推荐页首次 SPA 进入搜索页时宽屏布局未生效的问题。

它不读取账号信息，不调用知乎接口，不发送网络请求，不批量操作数据，只是给当前浏览器里的知乎页面注入样式和少量布局同步逻辑。

## 使用方式

先安装并启用这两个依赖脚本：

- [知乎增强](https://greasyfork.org/zh-CN/scripts/419081-zhihu-enhancement)
- [知乎美化](https://greasyfork.org/zh-CN/scripts/412212-%E7%9F%A5%E4%B9%8E%E7%BE%8E%E5%8C%96)

然后打开 GitHub 项目里的 [`zhihu-action-width-fix.user.js`](https://github.com/Onlydreams/zhihu-action-width-fix/blob/main/zhihu-action-width-fix.user.js)，在 Tampermonkey 新建脚本，把源码完整粘进去并保存。建议让这个脚本排在“知乎美化”“知乎增强”之后运行；保存后刷新知乎页面，让旧样式块失效。

后续更新时，直接用仓库里的最新 `zhihu-action-width-fix.user.js` 覆盖 Tampermonkey 里的旧版本。

## Fix 脚本源码

当前源码版本：`0.8.0`。

```javascript
// ==UserScript==
// @name         知乎操作栏宽度修正
// @namespace    local.zhihu-action-width-fix
// @version      0.8.0
// @description  修复知乎美化导致的操作栏错位，以及首次进入搜索页时宽屏布局未生效。
// @match        https://www.zhihu.com/*
// @run-at       document-idle
// @grant        GM_addStyle
// ==/UserScript==

(function () {
  'use strict';

  GM_addStyle(`
    /* 知乎美化只按首次加载路径注入搜索页规则，常驻规则用于覆盖 SPA 跳转。 */
    .SearchMain {
      width: inherit !important;
    }

    .SearchMain + div {
      display: none !important;
    }

    .TopstoryItem .ContentItem-actions:not(.ContentItem-action),
    .TopstoryItem .RichContent-actions:not(.ContentItem-action),
    .List-item .ContentItem-actions:not(.ContentItem-action),
    .List-item .RichContent-actions:not(.ContentItem-action) {
      box-sizing: border-box !important;
      transform: none !important;
    }
  `);

  const ACTION_SELECTOR = [
    '.TopstoryItem .ContentItem-actions:not(.ContentItem-action)',
    '.TopstoryItem .RichContent-actions:not(.ContentItem-action)',
    '.List-item .ContentItem-actions:not(.ContentItem-action)',
    '.List-item .RichContent-actions:not(.ContentItem-action)',
  ].join(',');

  const CONTENT_SELECTOR = [
    '.ContentItem-title',
    '.QuestionItem-title',
    '.ContentItem-meta',
    '.RichContent',
    '.RichText',
  ].join(',');

  const isVisible = (element) => {
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    return rect.width > 0 && rect.height > 0 && style.display !== 'none' && style.visibility !== 'hidden';
  };

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

  const findLayoutRoot = (actions) => {
    const searchCard = actions.closest('.SearchResult-Card');
    const contentItem = actions.closest('.ContentItem');
    if (searchCard && contentItem) return contentItem;

    return actions.closest('.TopstoryItem, .List-item, .Card');
  };

  const findContentInsets = (card, cardRect) => {
    const content = Array.from(card.querySelectorAll(CONTENT_SELECTOR)).find(isVisible);
    if (!content) return { left: 16, right: 16 };

    const contentRect = content.getBoundingClientRect();
    return {
      left: clamp(Math.round(contentRect.left - cardRect.left), 0, 40),
      right: clamp(Math.round(cardRect.right - contentRect.right), 0, 40),
    };
  };

  const normalizeNestedAction = (actions) => {
    const nested = actions.querySelector(
      ':scope > .ContentItem-actions.ContentItem-action, :scope > .RichContent-actions.ContentItem-action',
    );
    if (!nested) return;

    nested.style.setProperty('box-sizing', 'border-box', 'important');
    nested.style.setProperty('width', '100%', 'important');
    nested.style.setProperty('max-width', '100%', 'important');
    nested.style.setProperty('margin-left', '0', 'important');
    nested.style.setProperty('margin-right', '0', 'important');
    nested.style.setProperty('transform', 'none', 'important');

    // 搜索结果的嵌套行会重复继承外层操作栏间距，只保留外层间距。
    nested.style.setProperty('margin-bottom', '0', 'important');
    nested.style.setProperty('padding-top', '0', 'important');
    nested.style.setProperty('padding-bottom', '0', 'important');
  };

  const alignActionBar = (actions) => {
    const card = findLayoutRoot(actions);
    if (!card || !isVisible(actions)) return;

    const cardRect = card.getBoundingClientRect();
    if (cardRect.width <= 0) return;

    const computed = getComputedStyle(actions);
    const cardLeft = Math.round(cardRect.left);
    const cardWidth = Math.round(cardRect.width);
    const inset = findContentInsets(card, cardRect);
    actions.style.setProperty('box-sizing', 'border-box', 'important');
    actions.style.setProperty('width', `${cardWidth}px`, 'important');
    actions.style.setProperty('max-width', `${cardWidth}px`, 'important');
    actions.style.setProperty('padding-left', `${inset.left}px`, 'important');
    actions.style.setProperty('padding-right', `${inset.right}px`, 'important');
    actions.style.setProperty('transform', 'none', 'important');

    normalizeNestedAction(actions);

    if (computed.position === 'fixed') {
      actions.style.setProperty('left', `${cardLeft}px`, 'important');
      actions.style.setProperty('right', 'auto', 'important');
      actions.style.setProperty('margin-left', '0', 'important');
      actions.style.setProperty('margin-right', '0', 'important');
      return;
    }

    const parent = actions.parentElement;
    if (!parent) return;

    const parentRect = parent.getBoundingClientRect();
    const marginLeft = Math.round(cardRect.left - parentRect.left);

    actions.style.setProperty('left', 'auto', 'important');
    actions.style.setProperty('right', 'auto', 'important');
    actions.style.setProperty('margin-left', `${marginLeft}px`, 'important');
    actions.style.setProperty('margin-right', '0', 'important');
  };

  const alignActionBars = () => {
    document.querySelectorAll(ACTION_SELECTOR).forEach(alignActionBar);
  };

  let alignQueued = false;
  const queueAlign = () => {
    if (alignQueued) return;
    alignQueued = true;
    requestAnimationFrame(() => {
      alignQueued = false;
      alignActionBars();
    });
  };

  alignActionBars();
  window.addEventListener('scroll', queueAlign, { passive: true });
  window.addEventListener('resize', queueAlign);

  new MutationObserver(queueAlign).observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['class', 'style'],
  });
})();
```

## 为什么改成动态测量

知乎的普通折叠行、展开行、fixed / sticky 浮动条和搜索结果页操作栏类名接近，但布局状态不同。

早期版本用过固定 CSS：普通行用 `calc(100% + 32px)`，fixed 浮动条再单独读卡片宽度。这个方案能修最初的宽度外溢，但后面暴露了三个问题：

- 为了不误伤 fixed 浮动条而排除 `.Sticky`，会漏掉展开态的非 fixed 操作栏，例如 `.ContentItem-actions.Sticky.RichContent-actions.is-bottom`。
- 页面底部点击展开后，内容先展开到浏览器不可见区域，再滚动出来时，操作栏状态和父容器宽度会变化，固定 CSS 很容易继续错位。
- 搜索结果页外层 `.List-item` / `.SearchResult-Card` 比实际正文 `.ContentItem` 更宽，按外层测量会让按钮栏左右错位。

所以现在不再猜宽度，而是每次重新测量：

- 找到操作栏所在的 `.TopstoryItem`、`.List-item`、`.Card`，搜索结果页则优先使用 `.ContentItem`。
- 读取容器真实 `left` 和 `width`。
- 读取正文区域相对容器的左右缩进，用这个缩进设置按钮内边距。
- 如果操作栏是 `position: fixed`，直接同步 `left` 和 `width`。
- 如果操作栏不是 fixed，就根据父容器和测量根的相对位置设置 `margin-left`，让背景条回到正确范围内。
- 搜索结果页只清理嵌套操作行的重复纵向样式，不再覆盖外层操作栏原生上下间距。

脚本监听了 `scroll`、`resize` 和 DOM class/style 变化。知乎滚动、展开、收起、底部吸附和 SPA 跳转都会动态改类名和几何位置，必须在这些变化后重新校正。

## 版本演进

当前 GitHub 维护版把本地排查过程收敛成了几个版本：

- `0.6.0`：统一动态读取卡片真实位置和宽度，覆盖折叠、展开、非 fixed 和底部 fixed / sticky 操作栏。
- `0.7.0`：加入知乎搜索结果页处理；搜索结果中优先使用 `.ContentItem` 作为布局测量根，并用 `:not(.ContentItem-action)` 避免把嵌套单项误识别为外层操作栏。
- `0.7.1`：修复搜索结果页嵌套选择器重复命中，避免评论按钮和时间控件被扩成整行宽度。
- `0.7.2`：修复“最新讨论”等搜索结果中嵌套操作行重复继承外层下间距，导致下边缘越过卡片的问题。
- `0.8.0`：修复从推荐页通过 SPA 首次进入搜索页时，搜索页宽屏规则未注入、右侧信息栏残留的问题。

## 验证方式

仓库里有最小回归测试，更新脚本后先跑：

```powershell
node --check .\zhihu-action-width-fix.user.js
node --test --test-isolation=none .\test\userscript-source.test.js
```

浏览器里重点手工检查这些状态：

- 推荐流卡片折叠态；
- 推荐流卡片展开后的普通操作栏；
- 滚动到底部出现的 fixed / sticky 操作栏；
- 搜索结果页的折叠态与展开态；
- 从推荐页通过顶部搜索框首次进入搜索页，确认无需刷新即可隐藏右栏并扩展主栏；
- 调整浏览器窗口宽度后重新对齐。

## 注意事项

这个脚本属于本地补丁，适合自己浏览器里修正“知乎美化”和“知乎增强”叠加后的 UI 问题。它依赖知乎当前 DOM 类名和卡片结构，如果知乎改版，或者两个依赖脚本改了样式策略，可能需要重新量一次页面元素。

如果只装了其中一个脚本，或者你的知乎页面没有出现操作栏宽度问题，就不需要安装这个 fix。
