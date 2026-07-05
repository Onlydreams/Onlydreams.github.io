---
layout: post
title: "知乎美化/知乎增强本地 Fix：修正赞同操作栏展开与浮动错位"
date: 2026-07-05 11:35:00 +0800
updated: 2026-07-05
categories: [工具, 浏览器, 配置]
tags: [zhihu, tampermonkey, userscript, css, fix]
status:
  label: 当前可用
  verified: 2026-07-05
  environment: Tampermonkey / Chrome、Edge / 知乎网页 / 知乎美化、知乎增强脚本叠加后
  risk: 只修改本地页面样式，不修改知乎数据；知乎页面 DOM 或原脚本样式更新后可能需要重新调整。
---

这是一个安装了“知乎美化”和“知乎增强”之后的本地 fix 版脚本，用来修正知乎推荐流里“赞同 / 评论 / 分享”操作栏在折叠、展开、底部 fixed 浮动状态下的宽度和位置错位。它不是替代原脚本，而是在原脚本之后补一层本地布局修正。

---

## 原脚本分别做什么

“知乎美化”和“知乎增强”解决的是两个不同方向的问题。

“知乎美化”主要改知乎网页的视觉层：压缩多余留白、调整卡片和正文区域、弱化干扰元素，让推荐流和回答页更像一个适合阅读的页面。

“知乎增强”更偏功能增强：通常会补充屏蔽、过滤、快捷操作、页面行为优化等能力，用来绕开知乎官方设置里不够细的控制项，比如推荐流里按关键词或内容特征做更细粒度处理。

这两个脚本本身都有用，但叠加之后会一起影响知乎卡片结构和操作栏样式。本文这个脚本只处理叠加后的本地 UI 偏差，不承担内容过滤、推荐屏蔽或页面功能增强。

## 问题现象

装完“知乎美化”和“知乎增强”后，知乎推荐页和内容列表里的操作栏会出现两个细节问题：

- 普通卡片底部的“赞同 / 评论 / 分享”这一行宽度和卡片正文不一致。
- 页面滚动到底部时，知乎自己的 fixed / sticky 操作栏会比卡片宽一点，左右各多出几像素。
- 在页面底部点击展开，让内容展开到浏览器不可见区域后，再把页面滚动出来，展开态的非 fixed 操作栏仍可能错位。

前几版只用 CSS 强行改 `.ContentItem-actions` 宽度，或者把 fixed 浮动条单独处理。这个方向能修一部分场景，但在折叠、展开、底部 fixed 三种状态之间容易互相打架。最新 v0.6 的处理方式是：不再用 `calc(100% + 32px)` 这种固定 CSS 猜宽度，而是统一用 JS 动态读取所在卡片的真实 `left / width`。

- 普通折叠行：按所在卡片宽度对齐，按钮仍从正文左边距开始。
- 展开后的非 fixed 行：重新纳入动态对齐，不再被 `.Sticky` 类名误排除。
- 底部 fixed 浮动条：按所在卡片的真实左边界和宽度同步，窗口宽度变化后也会重新校正。

## 脚本功能

这个本地 fix 脚本做三件事：

1. 只处理知乎页面里的 `.TopstoryItem`、`.List-item` 等卡片操作栏。
2. 每条操作栏都找到它所在的卡片，读取卡片真实尺寸，再把操作栏宽度锁到卡片范围内。
3. 通过正文元素计算按钮左侧缩进，避免背景条对齐了但“赞同 / 评论 / 分享”按钮整体偏移。
4. 对滚动、窗口缩放、DOM 更新重新排队校正，覆盖折叠、展开和 fixed 浮动状态。

它不读取账号信息，不调用知乎接口，不批量操作数据，只是给当前浏览器里的知乎页面注入样式和少量布局同步逻辑。

## 使用方式

在 Tampermonkey 新建脚本，把下面源码完整粘进去并保存。建议让这个脚本排在“知乎美化”“知乎增强”之后运行；保存后刷新知乎页面，让旧样式块失效。

如果后续知乎改版或原脚本更新后又出现宽度偏差，优先重新检查这几个元素：

- `.ContentItem-actions`
- `.RichContent-actions`
- `.Sticky`
- `.is-fixed`
- `.is-bottom`
- `.TopstoryItem`
- `.List-item`
- `.Card`

## Fix 脚本源码

```javascript
// ==UserScript==
// @name         知乎操作栏宽度修正
// @namespace    local.zhihu-action-width-fix
// @version      0.6.0
// @description  修复知乎美化导致推荐流“赞同/评论/分享”操作栏在折叠、展开、底部浮动状态下宽度异常。
// @match        https://www.zhihu.com/*
// @run-at       document-idle
// @grant        GM_addStyle
// ==/UserScript==

(function () {
  'use strict';

  GM_addStyle(`
    .TopstoryItem .ContentItem-actions,
    .TopstoryItem .RichContent-actions,
    .List-item .ContentItem-actions,
    .List-item .RichContent-actions {
      box-sizing: border-box !important;
      transform: none !important;
    }
  `);

  const ACTION_SELECTOR = [
    '.TopstoryItem .ContentItem-actions',
    '.TopstoryItem .RichContent-actions',
    '.List-item .ContentItem-actions',
    '.List-item .RichContent-actions',
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

  const findContentInset = (card, cardRect) => {
    const content = Array.from(card.querySelectorAll(CONTENT_SELECTOR)).find(isVisible);
    if (!content) return 16;

    const contentRect = content.getBoundingClientRect();
    return clamp(Math.round(contentRect.left - cardRect.left), 0, 40);
  };

  const alignActionBar = (actions) => {
    const card = actions.closest('.TopstoryItem, .List-item, .Card');
    if (!card || !isVisible(actions)) return;

    const cardRect = card.getBoundingClientRect();
    if (cardRect.width <= 0) return;

    const computed = getComputedStyle(actions);
    const cardLeft = Math.round(cardRect.left);
    const cardWidth = Math.round(cardRect.width);
    const inset = findContentInset(card, cardRect);

    actions.style.setProperty('box-sizing', 'border-box', 'important');
    actions.style.setProperty('width', `${cardWidth}px`, 'important');
    actions.style.setProperty('max-width', `${cardWidth}px`, 'important');
    actions.style.setProperty('padding-left', `${inset}px`, 'important');
    actions.style.setProperty('padding-right', `${inset}px`, 'important');
    actions.style.setProperty('transform', 'none', 'important');

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

知乎的普通折叠行、展开行和 fixed / sticky 浮动条类名接近，但布局状态不同。

早期版本用过固定 CSS：普通行用 `calc(100% + 32px)`，fixed 浮动条再单独读卡片宽度。这个方案能修最初的宽度外溢，但后面暴露了两个问题：

- 为了不误伤 fixed 浮动条而排除 `.Sticky`，会漏掉展开态的非 fixed 操作栏，例如 `.ContentItem-actions.Sticky.RichContent-actions.is-bottom`。
- 页面底部点击展开后，内容先展开到浏览器不可见区域，再滚动出来时，操作栏状态和父容器宽度会变化，固定 CSS 很容易继续错位。

所以 v0.6 不再猜宽度，而是每次重新测量：

- 找到操作栏所在的 `.TopstoryItem`、`.List-item` 或 `.Card`。
- 读取卡片真实 `left` 和 `width`。
- 读取正文区域相对卡片的左缩进，用这个缩进设置按钮内边距。
- 如果操作栏是 `position: fixed`，直接同步 `left` 和 `width`。
- 如果操作栏不是 fixed，就根据父容器和卡片的相对位置设置 `margin-left`，让背景条回到卡片宽度内。

这也是为什么脚本监听了 `scroll`、`resize` 和 DOM class/style 变化：知乎滚动、展开、收起、底部吸附都会动态改类名和几何位置，必须在这些变化后重新校正。

## 注意事项

这个脚本属于本地补丁，适合自己浏览器里临时修正脚本叠加后的 UI 问题。它依赖知乎当前 DOM 类名和卡片结构，如果知乎改版，或者“知乎美化”“知乎增强”改了样式策略，可能需要重新量一次页面元素。

如果只装了其中一个脚本，或者你的知乎页面没有出现操作栏宽度问题，就不需要安装这个 fix。
