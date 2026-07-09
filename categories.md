---
layout: page
title: 分类
description: 按主题浏览 Onlydreams 的 macOS、AI、网络和开发工具技术笔记。
permalink: /categories/
---

<div class="taxonomy-page">
  <p class="taxonomy-intro">按主题查看文章。</p>

  {%- assign sorted_categories = site.categories | sort -%}
  {%- for category in sorted_categories -%}
    {%- assign category_name = category[0] -%}
    {%- assign posts = category[1] -%}
    <section class="taxonomy-section" id="category-{{ category_name | slugify: 'raw' }}">
      <h2>{{ category_name | escape }}</h2>
      <ul class="taxonomy-post-list">
        {%- for post in posts -%}
          <li>
            <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
            <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
          </li>
        {%- endfor -%}
      </ul>
    </section>
  {%- endfor -%}
</div>
