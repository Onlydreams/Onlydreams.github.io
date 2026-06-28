---
layout: page
title: 专题
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
          {%- for target_order in (1..20) -%}
            {%- for post in site.posts -%}
              {%- if post.series contains series.key -%}
                {%- assign post_order = post.series_order[series.key] -%}
                {%- if post_order == target_order -%}
                  <li class="series-post-item">
                    <article>
                      <div class="post-meta">
                        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
                        {%- if post.updated -%}
                          <span class="post-updated">• 更新于 {{ post.updated | date: "%Y-%m-%d" }}</span>
                        {%- endif -%}
                      </div>
                      <h3>
                        <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
                      </h3>
                      <p class="series-post-excerpt">
                        {{ post.excerpt | strip_html | normalize_whitespace | truncate: 120 }}
                      </p>
                      {%- if post.tags.size > 0 -%}
                        <ul class="series-post-tags" aria-label="文章标签">
                          {%- for tag in post.tags limit: 5 -%}
                            <li>
                              <a href="{{ '/tags/' | relative_url }}#tag-{{ tag | slugify: 'raw' }}">{{ tag }}</a>
                            </li>
                          {%- endfor -%}
                        </ul>
                      {%- endif -%}
                    </article>
                  </li>
                {%- endif -%}
              {%- endif -%}
            {%- endfor -%}
          {%- endfor -%}

          {%- for post in site.posts -%}
            {%- if post.series contains series.key -%}
              {%- assign post_order = post.series_order[series.key] -%}
              {%- unless post_order -%}
                <li class="series-post-item">
                  <article>
                    <div class="post-meta">
                      <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
                      {%- if post.updated -%}
                        <span class="post-updated">• 更新于 {{ post.updated | date: "%Y-%m-%d" }}</span>
                      {%- endif -%}
                    </div>
                    <h3>
                      <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
                    </h3>
                    <p class="series-post-excerpt">
                      {{ post.excerpt | strip_html | normalize_whitespace | truncate: 120 }}
                    </p>
                    {%- if post.tags.size > 0 -%}
                      <ul class="series-post-tags" aria-label="文章标签">
                        {%- for tag in post.tags limit: 5 -%}
                          <li>
                            <a href="{{ '/tags/' | relative_url }}#tag-{{ tag | slugify: 'raw' }}">{{ tag }}</a>
                          </li>
                        {%- endfor -%}
                      </ul>
                    {%- endif -%}
                  </article>
                </li>
              {%- endunless -%}
            {%- endif -%}
          {%- endfor -%}
        </ol>
      </section>
    {%- endif -%}
  {%- endfor -%}
</div>
