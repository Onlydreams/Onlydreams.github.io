---
layout: page
title: 标签
permalink: /tags/
---

<div class="taxonomy-page">
  <p class="taxonomy-intro">按关键词查看文章。</p>

  {%- assign sorted_tags = site.tags | sort -%}
  {%- for tag in sorted_tags -%}
    {%- assign tag_name = tag[0] -%}
    {%- assign posts = tag[1] -%}
    <section class="taxonomy-section" id="tag-{{ tag_name | slugify: 'raw' }}">
      <h2>{{ tag_name }}</h2>
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
