---
layout: page
title: 搜索
description: 在 Onlydreams 技术博客中按工具、命令和主题查找文章。
permalink: /search/
robots: noindex, follow
search: true
sitemap: false
---

<div class="search-page">
  <label class="search-label" for="search-input">搜索文章</label>
  <input
    id="search-input"
    class="search-input"
    type="search"
    autocomplete="off"
    placeholder="输入关键词、命令或工具名"
    data-search-index="{{ '/search.json' | relative_url }}"
  >
  <div class="search-filters" aria-label="筛选文章">
    <div class="search-filter">
      <label for="search-category">分类</label>
      <select id="search-category" name="category">
        <option value="">全部分类</option>
      </select>
    </div>
    <div class="search-filter">
      <label for="search-tag">标签</label>
      <select id="search-tag" name="tag">
        <option value="">全部标签</option>
      </select>
    </div>
    <div class="search-filter">
      <label for="search-status-filter">状态</label>
      <select id="search-status-filter" name="status">
        <option value="">全部状态</option>
      </select>
    </div>
  </div>
  <p id="search-status" class="search-status" aria-live="polite">输入关键词或选择筛选条件开始浏览。</p>
  <ol id="search-results" class="search-results"></ol>
</div>
