---
layout: default
title: English Articles
description: English editions of selected Onlydreams articles on AI agents, developer tooling, and evidence-driven workflows.
permalink: /en/
lang: en
translation_key: home
---

<div class="home">
  <h1 class="page-heading">English Articles</h1>
  <p>Selected English editions of original Chinese articles on AI agents, developer tooling, and evidence-driven workflows.</p>

  {%- assign english_posts = site.english_posts | sort: "date" | reverse -%}
  {%- if english_posts.size > 0 -%}
    <h2 class="post-list-heading">Latest English articles</h2>
    <ul class="post-list">
      {%- assign date_format = "%b %-d, %Y" -%}
      {%- for post in english_posts -%}
      <li>
        <div class="post-meta">
          <time datetime="{{ post.date | date_to_xmlschema }}">
            {{ post.date | date: date_format }}
          </time>
          {%- if post.updated -%}
            <span class="post-updated"> • Updated {{ post.updated | date: "%Y-%m-%d" }}</span>
          {%- endif -%}
        </div>
        <h3>
          <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
        </h3>
        <p class="post-card-excerpt">
          {{ post.excerpt | strip_html | normalize_whitespace | truncate: 180 }}
        </p>
        {%- if post.tags.size > 0 -%}
          <ul class="post-card-tags" aria-label="Article tags">
            {%- for tag in post.tags limit: 5 -%}
              <li><span>{{ tag | escape }}</span></li>
            {%- endfor -%}
          </ul>
        {%- endif -%}
      </li>
      {%- endfor -%}
    </ul>
  {%- endif -%}
</div>
