---
layout: page
title: 文章状态
permalink: /status/
---

<div class="status-page">
  <p class="status-intro">按可用性查看文章，优先识别当前可用、待复核或风险较高的技术笔记。</p>

  {%- assign status_labels = "当前可用|待复核|已失效" | split: "|" -%}
  {%- for status_label in status_labels -%}
    {%- assign status_post_count = 0 -%}
    {%- for post in site.posts -%}
      {%- assign post_status_label = post.status.label | default: "未标记" -%}
      {%- if post_status_label == status_label -%}
        {%- assign status_post_count = status_post_count | plus: 1 -%}
      {%- endif -%}
    {%- endfor -%}

    {%- if status_post_count > 0 -%}
      <section class="status-section" id="status-{{ status_label | slugify: 'raw' }}">
        <header class="status-section-header">
          <h2>{{ status_label | escape }}</h2>
          <span class="status-count">{{ status_post_count }} 篇</span>
        </header>
        <ul class="status-post-list">
          {%- for post in site.posts -%}
            {%- assign post_status_label = post.status.label | default: "未标记" -%}
            {%- if post_status_label == status_label -%}
              <li>
                <article>
                  <h3>
                    <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
                  </h3>
                  <dl class="status-post-meta">
                    {%- if post.status.verified -%}
                      <div>
                        <dt>最后验证</dt>
                        <dd>{{ post.status.verified | escape }}</dd>
                      </div>
                    {%- endif -%}
                    {%- if post.status.environment -%}
                      <div>
                        <dt>适用环境</dt>
                        <dd>{{ post.status.environment | escape }}</dd>
                      </div>
                    {%- endif -%}
                  </dl>
                  {%- if post.status.risk -%}
                    <p class="status-post-risk">{{ post.status.risk | escape }}</p>
                  {%- endif -%}
                </article>
              </li>
            {%- endif -%}
          {%- endfor -%}
        </ul>
      </section>
    {%- endif -%}
  {%- endfor -%}
</div>
