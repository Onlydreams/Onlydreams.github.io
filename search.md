---
layout: page
title: 搜索
permalink: /search/
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
  <p id="search-status" class="search-status" aria-live="polite">输入关键词开始搜索。</p>
  <ol id="search-results" class="search-results"></ol>
</div>
