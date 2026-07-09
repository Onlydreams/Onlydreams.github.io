---
layout: page
title: 专题
description: 沿着专题阅读 Onlydreams 的配置、排障和 AI Agent 工作流技术笔记。
permalink: /series/
---

<div class="series-page">
  <p class="series-intro">把相关技术笔记按阅读路径整理在一起，适合从一个问题顺着看完整条配置、排障或 Agent 工作流。</p>

  {%- for series in site.data.series -%}
    {%- assign series_post_count = 0 -%}
    {%- for post in site.posts -%}
      {%- if post.series contains series.key -%}
        {%- assign series_post_count = series_post_count | plus: 1 -%}
      {%- endif -%}
    {%- endfor -%}

    {%- if series_post_count > 0 -%}
      <section class="series-section" id="series-{{ series.key | slugify: 'raw' }}">
        <header class="series-section-header">
          <div>
            <h2>{{ series.title | escape }}</h2>
            <p>{{ series.description | escape }}</p>
          </div>
          <span class="series-count">{{ series_post_count }} 篇</span>
        </header>

        <ol class="series-post-list">
          {%- capture ordered_post_rows -%}
            {%- for post in site.posts -%}
              {%- if post.series contains series.key -%}
                {%- assign post_order = post.series_order[series.key] -%}
                {%- if post_order -%}
                  {%- assign padded_order = post_order | plus: 1000000 | prepend: "0000000000" | slice: -10, 10 -%}
                  {{ padded_order }}|{{ post.url }};;
                {%- endif -%}
              {%- endif -%}
            {%- endfor -%}
          {%- endcapture -%}

          {%- assign ordered_post_rows = ordered_post_rows | split: ";;" | sort -%}
          {%- for ordered_post_row in ordered_post_rows -%}
            {%- unless ordered_post_row == "" -%}
              {%- assign ordered_post_url = ordered_post_row | split: "|" | last -%}
              {%- for post in site.posts -%}
                {%- if post.url == ordered_post_url -%}
                  {%- include series-post-item.html post=post -%}
                {%- endif -%}
              {%- endfor -%}
            {%- endunless -%}
          {%- endfor -%}

          {%- for post in site.posts -%}
            {%- if post.series contains series.key -%}
              {%- assign post_order = post.series_order[series.key] -%}
              {%- unless post_order -%}
                {%- include series-post-item.html post=post -%}
              {%- endunless -%}
            {%- endif -%}
          {%- endfor -%}
        </ol>
      </section>
    {%- endif -%}
  {%- endfor -%}
</div>
