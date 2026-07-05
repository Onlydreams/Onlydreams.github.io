---
layout: post
title: "知乎美化/知乎增强本地 Fix：修正赞同操作栏宽度"
date: 2026-07-05 11:35:00 +0800
categories: [工具, 浏览器, 配置]
tags: [zhihu, tampermonkey, userscript, css, fix]
status:
  label: 当前可用
  verified: 2026-07-05
  environment: Tampermonkey / Chrome、Edge / 知乎网页 / 知乎美化、知乎增强脚本叠加后
  risk: 只修改本地页面样式，不修改知乎数据；知乎页面 DOM 或原脚本样式更新后可能需要重新调整。
---

这是一个安装了“知乎美化”和“知乎增强”之后的本地 fix 版脚本，用来修正知乎推荐流里“赞同 / 评论 / 分享”操作栏宽度不一致、底部 fixed 浮动操作栏略微超宽的问题。它不是替代原脚本，而是在原脚本之后补一层本地样式修正。

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

第一版只用 CSS 强行改 `.ContentItem-actions` 宽度，后来发现会误伤知乎自己的 fixed 浮动条。真正稳定一点的处理方式，是把普通卡片操作栏和 fixed 浮动条分开处理：

- 普通卡片操作栏：用 CSS 调整宽度、左右 margin 和 padding，让它和正文视觉对齐。
- fixed / sticky 浮动条：用 JS 读取所在卡片真实的 `left` 和 `width`，再把浮动条同步到同样的位置和宽度。

## 脚本功能

这个本地 fix 脚本做三件事：

1. 只处理知乎页面里的 `.TopstoryItem`、`.List-item` 等卡片操作栏。
2. 明确排除普通 CSS 修正对 `.Sticky`、`.is-fixed` 操作栏的影响，避免把知乎浮动操作栏顶到页面底部或拉宽。
3. 对已经固定到底部的操作栏，实时读取父级卡片尺寸，滚动、缩放、DOM 更新时重新对齐。

它不读取账号信息，不调用知乎接口，不批量操作数据，只是给当前浏览器里的知乎页面注入样式和少量布局同步逻辑。

## 使用方式

在 Tampermonkey 新建脚本，把下面源码完整粘进去并保存。建议让这个脚本排在“知乎美化”“知乎增强”之后运行；保存后刷新知乎页面，让旧样式块失效。

如果后续知乎改版或原脚本更新后又出现宽度偏差，优先重新检查这几个元素：

- `.ContentItem-actions`
- `.RichContent-actions`
- `.Sticky`
- `.is-fixed`
- `.TopstoryItem`
- `.List-item`

## Fix 脚本源码

```javascript
// ==UserScript==
// @name         知乎操作栏宽度修正
// @namespace    local.zhihu-action-width-fix
// @version      0.4.0
// @description  修复知乎美化导致推荐流“赞同/评论/分享”操作栏宽度异常，同时保留按钮与正文左侧对齐。
// @match        https://www.zhihu.com/*
// @run-at       document-idle
// @grant        GM_addStyle
// ==/UserScript==

(function () {
  'use strict';

  GM_addStyle(`
    .TopstoryItem .ContentItem-actions:not(.Sticky):not(.is-fixed),
    .TopstoryItem .RichContent-actions:not(.Sticky):not(.is-fixed),
    .List-item .ContentItem-actions:not(.Sticky):not(.is-fixed),
    .List-item .RichContent-actions:not(.Sticky):not(.is-fixed) {
      box-sizing: border-box !important;
      width: calc(100% + 32px) !important;
      max-width: calc(100% + 32px) !important;
      margin-left: -16px !important;
      margin-right: -16px !important;
      padding-left: 16px !important;
      padding-right: 16px !important;
      left: 0 !important;
      right: auto !important;
      transform: none !important;
    }

  `);

  const alignFixedActionBars = () => {
    document
      .querySelectorAll('.ContentItem-actions.Sticky.is-fixed, .RichContent-actions.Sticky.is-fixed')
      .forEach((actions) => {
        const card = actions.closest('.TopstoryItem, .List-item, .Card');
        if (!card) return;

        const cardRect = card.getBoundingClientRect();
        if (cardRect.width <= 0) return;

        actions.style.setProperty('box-sizing', 'border-box', 'important');
        actions.style.setProperty('left', `${Math.round(cardRect.left)}px`, 'important');
        actions.style.setProperty('right', 'auto', 'important');
        actions.style.setProperty('width', `${Math.round(cardRect.width)}px`, 'important');
        actions.style.setProperty('max-width', `${Math.round(cardRect.width)}px`, 'important');
        actions.style.setProperty('margin-left', '0', 'important');
        actions.style.setProperty('margin-right', '0', 'important');
        actions.style.setProperty('padding-left', '16px', 'important');
        actions.style.setProperty('padding-right', '16px', 'important');
        actions.style.setProperty('transform', 'none', 'important');
      });
  };

  let alignQueued = false;
  const queueAlign = () => {
    if (alignQueued) return;
    alignQueued = true;
    requestAnimationFrame(() => {
      alignQueued = false;
      alignFixedActionBars();
    });
  };

  alignFixedActionBars();
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

## 为什么要单独处理 fixed 浮动条

知乎的普通卡片操作栏和 fixed / sticky 浮动条虽然类名接近，但布局语义不同。

普通卡片操作栏是在卡片内部排版，适合用 CSS 做局部样式覆盖。fixed 浮动条脱离了普通文档流，会受 `left`、`width`、`transform`、页面滚动位置和视口宽度影响。如果直接把普通卡片那套 `width + margin` 规则套到 fixed 元素上，就容易出现浮动条跑到页面底部、宽度超出卡片的问题。

所以 v0.4 的处理逻辑是：

- CSS 只覆盖 `:not(.Sticky):not(.is-fixed)` 的普通操作栏。
- JS 只处理 `.Sticky.is-fixed` 的浮动条。
- 浮动条宽度不写死，始终以它所在卡片的实时尺寸为准。

## 注意事项

这个脚本属于本地补丁，适合自己浏览器里临时修正脚本叠加后的 UI 问题。它依赖知乎当前 DOM 类名，如果知乎改版，或者“知乎美化”“知乎增强”改了样式策略，可能需要重新量一次页面元素。

如果只装了其中一个脚本，或者你的知乎页面没有出现操作栏宽度问题，就不需要安装这个 fix。
