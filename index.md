---
layout: home
---

欢迎来到 Onlydreams 的技术博客。

这里记录开发工具配置、效率提升技巧以及日常踩坑总结。

## 最新文章

{% for post in site.posts limit:5 %}
- [{{ post.title }}]({{ post.url | relative_url }}) — {{ post.date | date: "%Y-%m-%d" }}
{% endfor %}
