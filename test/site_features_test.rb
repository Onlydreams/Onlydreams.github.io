# frozen_string_literal: true

require "minitest/autorun"
require "date"
require "json"
require "liquid"
require "open3"
require "tmpdir"
require "yaml"

require_relative "../.github/scripts/indexnow"

class SiteFeaturesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SITE = File.join(ROOT, "_site")

  def read_site(path)
    File.read(File.join(SITE, path))
  end

  def read_scss_sources
    scss_paths = [File.join(ROOT, "assets/main.scss")]
    scss_paths.concat(Dir[File.join(ROOT, "_sass/**/*.scss")].sort)

    scss_paths.map { |path| File.read(path) }.join("\n")
  end

  def test_category_index_lists_existing_categories_and_posts
    html = read_site("categories/index.html")

    assert_includes html, "分类"
    assert_includes html, "MacOS"
    assert_includes html, "Git"
    assert_includes html, "/posts/macos-claude-deepseek/"
    assert_includes html, "/posts/auto-proxy-setup/"
  end

  def test_tag_index_lists_existing_tags_and_posts
    html = read_site("tags/index.html")

    assert_includes html, "标签"
    assert_includes html, "claude"
    assert_includes html, "proxy"
    assert_includes html, "/posts/macos-claude-deepseek/"
    assert_includes html, "/posts/auto-proxy-setup/"
  end

  def test_series_page_lists_configured_series_and_posts
    html = read_site("series/index.html")
    styles = read_scss_sources

    assert_includes html, "专题"
    assert_includes html, "AI Agent 工作流"
    assert_includes html, "网络与代理排障"
    assert_includes html, "macOS 开发工具链"
    assert_includes html, "/posts/skillshare-guide/"
    assert_includes html, "/posts/auto-proxy-setup/"
    assert_includes html, "/posts/macos-claude-deepseek/"
    assert_includes html, "/posts/worldcup-predictor-agent-skill/"
    assert_includes html, 'class="series-post-tags"'
    assert_includes styles, ".series-page"
    assert_includes styles, ".series-section"
    assert_includes styles, ".series-post-tags"

    ai_agent_index = html.index("AI Agent 工作流")
    network_proxy_index = html.index("网络与代理排障")
    macos_tooling_index = html.index("macOS 开发工具链")
    assert_operator ai_agent_index, :<, network_proxy_index
    assert_operator network_proxy_index, :<, macos_tooling_index

    skillshare_index = html.index("/posts/skillshare-guide/", ai_agent_index)
    agents_index = html.index("/posts/global-agents-context/", ai_agent_index)
    codex_index = html.index("/posts/codex-desktop-gpu-rendering-bug/", ai_agent_index)
    worldcup_index = html.index("/posts/worldcup-predictor-agent-skill/", ai_agent_index)
    assert_operator skillshare_index, :<, agents_index
    assert_operator agents_index, :<, codex_index
    assert_operator codex_index, :<, worldcup_index

    homebrew_index = html.index("/posts/macos-homebrew-acceleration/", network_proxy_index)
    git_proxy_index = html.index("/posts/auto-proxy-setup/", network_proxy_index)
    clash_index = html.index("/posts/clash-verge-github-node-speed-test/", network_proxy_index)
    diagnosis_index = html.index("/posts/ai-network-diagnosis-optimization-prompt/", network_proxy_index)
    assert_operator homebrew_index, :<, git_proxy_index
    assert_operator git_proxy_index, :<, clash_index
    assert_operator clash_index, :<, diagnosis_index
  end

  def test_status_page_groups_posts_by_status
    html = read_site("status/index.html")
    styles = read_scss_sources

    assert_includes html, "文章状态"
    assert_includes html, "当前可用"
    assert_includes html, "待复核"
    assert_includes html, "/posts/global-agents-context/"
    assert_includes html, "/posts/worldcup-predictor-agent-skill/"
    assert_includes html, "/posts/macos-homebrew-acceleration/"
    assert_includes html, "Codex / Claude / AGENTS.md"
    assert_includes html, "会修改包管理源、终端代理和 shell 配置"
    assert_includes html, 'class="status-post-list"'
    assert_includes html, 'class="status-post-risk"'
    assert_includes styles, ".status-page"
    assert_includes styles, ".status-section"
    assert_includes styles, ".status-post-risk"

    current_status_index = html.index("<h2>当前可用</h2>")
    needs_review_index = html.index("<h2>待复核</h2>")
    global_agents_index = html.index("/posts/global-agents-context/", current_status_index)
    worldcup_index = html.index("/posts/worldcup-predictor-agent-skill/", current_status_index)
    homebrew_index = html.index("/posts/macos-homebrew-acceleration/", needs_review_index)
    refute_nil current_status_index
    refute_nil needs_review_index
    refute_nil global_agents_index
    refute_nil worldcup_index
    refute_nil homebrew_index
    assert_operator current_status_index, :<, global_agents_index
    assert_operator global_agents_index, :<, needs_review_index
    assert_operator current_status_index, :<, worldcup_index
    assert_operator worldcup_index, :<, needs_review_index
    assert_operator needs_review_index, :<, homebrew_index
  end

  def test_site_navigation_links_to_series_page
    html = read_site("index.html")

    assert_includes html, 'href="/series/"'
    assert_includes html, ">专题</a>"
  end

  def test_site_navigation_links_to_status_page
    html = read_site("index.html")

    assert_includes html, 'href="/status/"'
    assert_includes html, ">文章状态</a>"
  end

  def test_site_navigation_uses_explicit_page_allowlist
    config = YAML.load_file(File.join(ROOT, "_config.yml"))

    assert_equal(
      ["about.md", "categories.md", "search.md", "series.md", "status.md", "tags.md"],
      config["header_pages"]
    )
  end

  def test_internal_docs_are_not_published_or_listed_in_navigation
    html = read_site("index.html")

    refute_includes html, "文章状态信息块实现计划"
    refute_includes html, "文章状态信息块设计"
    refute_includes html, "专题页实现计划"
    refute_includes html, "专题页设计"
    refute_includes html, 'href="/docs/'
    refute_path_exists File.join(SITE, "docs")
  end

  def test_internal_maintenance_scripts_are_not_published
    refute_path_exists File.join(SITE, "bin")
    refute_path_exists File.join(SITE, "bin", "test")
    refute_path_exists File.join(SITE, "bin", "test.ps1")
  end

  def test_post_pages_render_status_block_when_status_front_matter_exists
    html = read_site("posts/global-agents-context/index.html")
    styles = read_scss_sources

    assert_includes html, 'class="post-status"'
    assert_includes html, 'class="post-status-title"'
    assert_includes html, "文章状态"
    assert_includes html, "状态"
    assert_includes html, "当前可用"
    assert_includes html, "最后验证"
    assert_includes html, "2026-06-29"
    assert_includes html, "适用环境"
    assert_includes html, "Codex / Claude / AGENTS.md"
    assert_includes html, "风险提示"
    assert_includes html, "这是个人协作规则模板"
    assert_includes styles, ".post-status"
    assert_includes styles, ".post-status-title"
    assert_includes styles, ".post-status-list"
  end

  def test_status_block_does_not_render_on_regular_pages
    html = read_site("about/index.html")

    refute_includes html, 'class="post-status"'
  end

  def test_status_verified_does_not_create_date_modified
    post_path = Dir[File.join(ROOT, "_posts/*.md")].find do |path|
      front_matter = post_front_matter(path)

      front_matter["status"] && !front_matter.key?("updated")
    end

    refute_nil post_path, "expected at least one post with status metadata and no updated field"

    slug = File.basename(post_path, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
    html = read_site("posts/#{slug}/index.html")

    refute_includes html, 'itemprop="dateModified"'
  end

  def post_front_matter(path)
    match = File.read(path).match(/\A---\s*\n(.*?)\n---\s*\n/m)

    refute_nil match, "#{path} must start with YAML front matter"

    YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true)
  end

  def test_post_status_include_skips_blank_fields_and_escapes_values
    html = render_post_status(
      "label" => " <strong>当前可用</strong> ",
      "verified" => "",
      "environment" => "   ",
      "risk" => "Risk <script>alert(1)</script>"
    )

    assert_includes html, "<dt>状态</dt>"
    assert_includes html, "&lt;strong&gt;当前可用&lt;/strong&gt;"
    assert_includes html, "<dt>风险提示</dt>"
    assert_includes html, "Risk &lt;script&gt;alert(1)&lt;/script&gt;"
    refute_includes html, "<dt>最后验证</dt>"
    refute_includes html, "<dt>适用环境</dt>"
    refute_includes html, "<strong>当前可用</strong>"
    refute_includes html, "<script>"
  end

  def test_post_pages_render_toc
    html = read_site("posts/auto-proxy-setup/index.html")

    assert_includes html, 'class="post-toc"'
    assert_includes html, 'data-toc-source=".post-content"'
    assert_includes html, "目录需要启用 JavaScript 后显示。"
    refute_includes html, "toc_from_html"
  end

  def test_toc_is_generated_without_custom_jekyll_plugins
    script = File.read(File.join(ROOT, "assets/js/page-enhancements.js"))

    assert_includes script, "initPostToc"
    assert_includes script, "querySelectorAll(\"h2[id], h3[id]\")"
    assert_includes script, "data-toc-source"
    assert_includes script, "window.SiteEnhancements.initPostToc"
    refute_path_exists File.join(ROOT, "_plugins", "toc_filter.rb")
    refute_path_exists File.join(ROOT, ".github", "workflows", "pages.yml")
  end

  def test_client_toc_builds_nested_links_from_article_headings
    result = run_page_enhancements_dom_test(<<~JS)
      const toc = buildToc([
        new Element("h2", { id: "intro", textContent: "Intro <safe>" }),
        new Element("h3", { id: "details", textContent: "Details" }),
        new Element("h2", { id: "next", textContent: "Next" })
      ]);

      assert(toc.hidden === false, "toc should be visible");
      assert(toc.list.children.length === 2, "toc should contain two top-level items");
      assert(toc.list.children[0].children[0].href === "#intro", "first link should target first h2");
      assert(toc.list.children[0].children[0].textContent === "Intro <safe>", "link text should use textContent");
      assert(toc.list.children[0].children[1].children[0].children[0].href === "#details", "h3 should nest below previous h2");
      assert(toc.list.children[1].children[0].href === "#next", "second h2 should be top-level");
    JS

    assert_equal "", result
  end

  def test_client_toc_hides_empty_heading_lists
    result = run_page_enhancements_dom_test(<<~JS)
      const toc = buildToc([]);
      assert(toc.hidden === true, "toc should stay hidden without headings");
      assert(toc.list.children.length === 0, "empty toc should not create items");
    JS

    assert_equal "", result
  end

  def test_code_copy_button_behavior_is_available
    script = File.read(File.join(ROOT, "assets/js/code-copy.js"))

    assert_includes script, "initCodeCopyButtons"
    assert_includes script, "navigator.clipboard.writeText"
    assert_includes script, "copyTextFallback"
    assert_includes script, "return copyTextFallback(text)"
    assert_includes script, "getPromptCommand"
    assert_includes script, "isCommandBlock"
    assert_includes script, "copyText(getCopyText(wrapper, code))"
    assert_includes script, "code-copy-button"
    assert_includes script, "existingButtons"
    assert_includes script, "button.remove()"
    assert_includes script, "button.disabled = true"
    assert_includes script, "button.dataset.defaultLabel"
    assert_includes script, 'button.setAttribute("aria-live", "polite")'

    styles = read_scss_sources
    assert_includes styles, "min-width: 4.75rem"
    assert_includes styles, '.code-copy-button[data-state="success"]'
    assert_includes styles, '.code-copy-button[data-state="error"]'
    assert_includes styles, ".code-copy-button:focus-visible"
  end

  def test_code_copy_button_strips_shell_prompts_only_for_command_blocks
    result = run_code_copy_dom_test

    assert_equal(
      {
        "button_labels" => ["复制命令", "复制", "复制命令", "复制命令"],
        "copied_texts" => [
          "brew install ruby\nbundle install",
          "> keep this quoted text",
          "# script comment\nbrew update\nbrew install ruby",
          "cat <<'EOF'\nhello\nEOF\nprintf done \\\n  now"
        ]
      },
      result
    )
  end

  def test_search_page_and_index_are_available
    html = read_site("search/index.html")
    index = JSON.parse(read_site("search.json"))
    script = File.read(File.join(ROOT, "assets/js/search.js"))

    assert_includes html, 'id="search-input"'
    assert_includes html, 'id="search-results"'
    assert_includes html, "/search.json"
    assert index.any? { |item| item["title"].include?("Claude") && item["url"] == "/posts/macos-claude-deepseek/" }
    assert index.all? { |item| item["content"].length <= 320 }
    assert_includes script, "initSiteSearch"
    assert_includes script, "renderSearchResults"
    assert_includes script, "加载搜索索引"
    assert_includes script, "compositionstart"
    assert_includes script, "compositionend"
    assert_includes script, "if (composing) return"
  end

  def test_posts_render_updated_time_when_present
    html = read_site("posts/macos-claude-deepseek/index.html")

    assert_includes html, "更新于"
    assert_includes html, "2026-05-09"
    assert_includes html, 'itemprop="dateModified"'
  end

  def test_markdown_images_render_with_lazy_loading_hints
    html = read_site("posts/macos-claude-deepseek/index.html")

    assert_includes html, 'src="/assets/images/2026-04-30-macos-claude-deepseek/config.jpg"'
    assert_includes html, 'alt="Claude 配置"'
    assert_includes html, 'loading="lazy"'
    assert_includes html, 'decoding="async"'
  end

  def test_home_page_shows_excerpts_tags_and_updated_time
    html = read_site("index.html")
    updated_html = read_site("page2/index.html")
    tags_html = read_site("tags/index.html")

    assert_includes html, 'class="post-card-excerpt"'
    assert_includes html, 'class="post-card-tags"'
    assert_includes html, "/tags/#tag-codex"
    assert_includes tags_html, 'id="tag-codex"'
    assert_includes updated_html, 'class="post-updated"'
    assert_includes updated_html, "<time datetime="
  end

  def test_public_contact_uses_github_without_noreply_email
    home_html = read_site("index.html")
    about_html = read_site("about/index.html")

    refute_includes home_html, "mailto:"
    refute_includes home_html, "users.noreply.github.com"
    assert_includes home_html, "https://github.com/Onlydreams"
    assert_includes about_html, "技术交流可以通过文章评论或 GitHub 联系我。"
  end

  def test_post_pages_render_adjacent_post_navigation
    html = read_site("posts/global-agents-context/index.html")

    assert_includes html, 'class="post-adjacent-nav"'
    assert_includes html, "上一篇"
    assert_includes html, "/posts/skillshare-guide/"
    assert_includes html, "下一篇"
    assert_includes html, "/posts/codex-desktop-gpu-rendering-bug/"
  end

  def test_post_adjacent_navigation_renders_before_comments
    html = read_site("posts/codex-desktop-gpu-rendering-bug/index.html")

    adjacent_index = html.index('class="post-adjacent-nav"')
    comments_index = html.index('class="giscus-comments"')

    refute_nil adjacent_index
    refute_nil comments_index
    assert_operator adjacent_index, :<, comments_index
  end

  def test_single_adjacent_post_navigation_uses_directional_half_width_on_desktop
    styles = read_scss_sources

    assert_includes styles, "grid-template-columns: repeat(2, minmax(0, 1fr))"
    assert_includes styles, ".post-adjacent-link.next"
    assert_includes styles, "grid-column: 2"
    refute_includes styles, ".post-adjacent-link:only-child"
  end

  def test_post_pages_render_related_posts
    html = read_site("posts/codex-desktop-gpu-rendering-bug/index.html")
    related_posts = html[/<section class="related-posts".*?<\/section>/m]

    assert_includes html, 'class="related-posts"'
    assert_includes html, "相关文章"
    refute_nil related_posts
    assert_match(%r{href="/posts/[^"]+/"}, related_posts)
    assert_includes related_posts, '<span class="related-post-tags">'
    assert_match(%r{<span class="related-post-tags">\s*[^<]+ / [^<]+ / [^<]+\s*</span>}m, related_posts)
  end

  def test_posts_render_giscus_comments
    html = read_site("posts/macos-claude-deepseek/index.html")

    assert_includes html, "https://giscus.app/client.js"
    assert_includes html, 'data-repo="Onlydreams/Onlydreams.github.io"'
    assert_includes html, 'data-category="Announcements"'
    assert_includes html, 'data-theme-light="https://www.dayjia.com/assets/giscus-theme.css"'
    assert_includes html, 'data-theme-dark="https://www.dayjia.com/assets/giscus-theme-dark.css"'
    assert_includes html, 'data-lang="zh-CN"'
    refute_includes html, "https://onlydreams.github.io"

    script = File.read(File.join(ROOT, "assets/js/theme-toggle.js"))
    refute_includes script, "const GISCUS_LIGHT ="
    refute_includes script, "const GISCUS_DARK ="
    assert_includes script, "getGiscusThemeUrl"
  end

  def test_cloudflare_web_analytics_is_configurable_and_production_only
    html = read_site("index.html")
    config = File.read(File.join(ROOT, "_config.yml"))
    custom_head = File.read(File.join(ROOT, "_includes/custom-head.html"))

    assert_includes config, "cloudflare_web_analytics:"
    assert_match(/token: "[a-f0-9]{32}"/, config)
    assert_includes custom_head, "static.cloudflareinsights.com/beacon.min.js"
    assert_includes custom_head, 'data-cf-beacon'
    assert_includes custom_head, 'jekyll.environment == "production"'
    refute_includes html, "static.cloudflareinsights.com/beacon.min.js"
  end

  def test_google_fonts_are_loaded_from_head_without_css_import
    head = File.read(File.join(ROOT, "_includes/head.html"))
    main_scss = File.read(File.join(ROOT, "assets/main.scss"))

    assert_includes head, 'rel="preconnect" href="https://fonts.googleapis.com"'
    assert_includes head, 'rel="preconnect" href="https://fonts.gstatic.com" crossorigin'
    assert_includes head, "fonts.googleapis.com/css2?family=Poppins"
    assert_includes head, "&amp;family=Lora"
    assert_includes head, "&amp;display=swap"
    refute_includes main_scss, "@import url(\"https://fonts.googleapis.com"
  end

  def test_dynamic_taxonomy_labels_are_escaped_in_templates
    categories_page = File.read(File.join(ROOT, "categories.md"))
    tags_page = File.read(File.join(ROOT, "tags.md"))
    index_page = File.read(File.join(ROOT, "index.html"))
    related_posts = File.read(File.join(ROOT, "_includes", "related-posts.html"))
    series_post_item = File.read(File.join(ROOT, "_includes", "series-post-item.html"))

    assert_includes categories_page, "{{ category_name | escape }}"
    assert_includes tags_page, "{{ tag_name | escape }}"
    assert_includes index_page, "{{ tag | escape }}"
    assert_includes related_posts, '{{ post.tags | slice: 0, 3 | join: " / " | escape }}'
    assert_includes series_post_item, "{{ tag | escape }}"

    categories_html = read_site("categories/index.html")
    tags_html = read_site("tags/index.html")
    assert_includes categories_html, "<h2>AI</h2>"
    assert_includes tags_html, "<h2>codex</h2>"
  end

  def test_default_layout_loads_split_javascript_modules
    html = read_site("posts/auto-proxy-setup/index.html")
    expected_scripts = [
      "/assets/js/theme-toggle.js",
      "/assets/js/page-enhancements.js",
      "/assets/js/code-copy.js",
      "/assets/js/search.js"
    ]

    script_positions = expected_scripts.map do |script_path|
      assert_includes html, %("#{script_path}" defer)
      html.index(script_path)
    end

    assert_equal script_positions.sort, script_positions
    refute_includes html, "/assets/js/theme.js"
  end

  def test_cross_platform_test_entrypoints_are_available
    bash_script = File.read(File.join(ROOT, "bin/test"))
    powershell_script = File.read(File.join(ROOT, "bin/test.ps1"))

    assert_includes bash_script, "bundle exec ruby test/site_features_test.rb"
    assert_includes powershell_script, "bundle exec jekyll build"
    assert_includes powershell_script, "bundle exec ruby test/site_features_test.rb"
    assert_includes powershell_script, "$LASTEXITCODE"
  end

  def test_indexnow_wait_checks_expected_site_urls
    script = File.read(File.join(ROOT, ".github/scripts/indexnow.rb"))

    assert_includes script, "expected_site_urls"
    assert_includes script, "missing_urls"
    assert_includes script, "Missing sitemap URLs"
    refute_includes script, "minimum_sitemap_url_count"
  end

  def test_indexnow_expected_urls_come_from_built_sitemap
    Dir.mktmpdir do |dir|
      sitemap_path = File.join(dir, "sitemap.xml")
      File.write(sitemap_path, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.dayjia.com/custom-post-path/</loc></url>
          <url><loc>https://other.example.com/ignored/</loc></url>
        </urlset>
      XML

      indexnow = IndexNow.new(
        "INDEXNOW_HOST" => "www.dayjia.com",
        "EXPECTED_SITEMAP_PATH" => sitemap_path
      )

      assert_equal ["https://www.dayjia.com/custom-post-path/"], indexnow.send(:expected_site_urls)
    end
  end

  def test_indexnow_wait_retries_ssl_certificate_errors
    indexnow = IndexNow.new("INDEXNOW_HOST" => "www.dayjia.com")

    def indexnow.fetch_body!(_uri)
      raise OpenSSL::SSL::SSLError, "certificate verify failed (hostname mismatch)"
    end

    _, warning = capture_io do
      assert_equal "", indexnow.send(:fetch_body, URI("https://www.dayjia.com/sitemap.xml"))
    end

    assert_includes warning, "OpenSSL::SSL::SSLError"
    assert_includes warning, "certificate verify failed"
  end

  def test_indexnow_workflow_builds_local_sitemap_before_waiting
    workflow = File.read(File.join(ROOT, ".github/workflows/indexnow.yml"))

    assert_includes workflow, "bundle exec jekyll build"
    assert_includes workflow, "EXPECTED_SITEMAP_PATH: _site/sitemap.xml"
    assert_includes workflow, "INDEXNOW_HOST: www.dayjia.com"
    assert_includes workflow, "KEY_URL: https://www.dayjia.com/34366ad016cd48238ee20158d2a43852.txt"
    assert_includes workflow, "SITEMAP_URL: https://www.dayjia.com/sitemap.xml"
    assert_includes workflow, "INDEXNOW_KEY_LOCATION: https://www.dayjia.com/34366ad016cd48238ee20158d2a43852.txt"
    assert_includes workflow, "continue-on-error: true"
    assert_includes workflow, "if: steps.wait_for_sitemap.outcome == 'success'"
    refute_includes workflow, "onlydreams.github.io"
  end

  def test_indexnow_workflow_triggers_for_public_surface_changes
    workflow = File.read(File.join(ROOT, ".github/workflows/indexnow.yml"))

    [
      "_data/**",
      "series.md",
      "status.md",
      "bin/**",
      "test/**"
    ].each do |path|
      assert_includes workflow, %("#{path}")
    end
  end

  def test_ci_workflow_runs_full_site_tests
    workflow_path = File.join(ROOT, ".github/workflows/ci.yml")

    assert_path_exists workflow_path
    workflow = File.read(workflow_path)
    assert_includes workflow, "bundle exec jekyll build"
    assert_includes workflow, "bundle exec ruby test/site_features_test.rb"
    assert_includes workflow, "bundle exec ruby test/content_health_test.rb"
  end

  def run_page_enhancements_dom_test(scenario)
    page_script = File.read(File.join(ROOT, "assets/js/page-enhancements.js"))
    runner = <<~JS
      const vm = require("node:vm");

      class Element {
        constructor(tagName, options = {}) {
          this.tagName = tagName.toUpperCase();
          this.id = options.id || "";
          this.textContent = options.textContent || "";
          this.dataset = options.dataset || {};
          this.children = [];
          this.hidden = Boolean(options.hidden);
          this.href = "";
        }

        appendChild(child) {
          child.parentElement = this;
          child.parentNode = this;
          this.children.push(child);
          return child;
        }

        querySelector(selector) {
          return this.querySelectorAll(selector)[0] || null;
        }

        querySelectorAll(selector) {
          const matches = [];

          function visit(node) {
            if (selector === "#markdown-toc" && node.id === "markdown-toc") {
              matches.push(node);
            } else if (selector === "ul" && node.tagName === "UL") {
              matches.push(node);
            } else if (
              selector === "h2[id], h3[id]" &&
              (node.tagName === "H2" || node.tagName === "H3") &&
              node.id
            ) {
              matches.push(node);
            }

            node.children.forEach(visit);
          }

          this.children.forEach(visit);
          return matches;
        }
      }

      function assert(condition, message) {
        if (!condition) {
          throw new Error(message);
        }
      }

      const document = {
        readyState: "loading",
        nodes: {},
        addEventListener() {},
        createElement(tagName) {
          return new Element(tagName);
        },
        getElementById() {
          return null;
        },
        querySelector(selector) {
          if (selector === ".post-toc[data-toc-source]") return this.nodes.toc || null;
          if (selector === ".post-content") return this.nodes.source || null;
          return null;
        },
        querySelectorAll() {
          return [];
        }
      };

      const window = {
        document,
        location: { pathname: "/" },
        addEventListener() {},
        requestAnimationFrame(callback) {
          callback();
        },
        matchMedia() {
          return { matches: false };
        }
      };

      function buildToc(headings) {
        const toc = new Element("aside", {
          dataset: { tocSource: ".post-content" },
          hidden: true
        });
        const list = new Element("ul", { id: "markdown-toc" });
        const source = new Element("div");

        headings.forEach((heading) => source.appendChild(heading));
        toc.appendChild(list);
        toc.list = list;
        document.nodes = { toc, source };

        window.SiteEnhancements.initPostToc();
        return toc;
      }

      const sandbox = {
        Element,
        URL,
        assert,
        buildToc,
        document,
        window
      };

      vm.runInNewContext(#{JSON.generate(page_script)}, sandbox);
      vm.runInNewContext(#{JSON.generate(scenario)}, sandbox);
    JS

    stdout, stderr, status = Open3.capture3("node", "-", stdin_data: runner)

    assert status.success?, stderr

    stdout.strip
  end

  def render_post_status(status)
    template = Liquid::Template.parse(File.read(File.join(ROOT, "_includes", "post-status.html")))

    template.render!("page" => { "status" => status })
  end

  def run_code_copy_dom_test
    code_copy_script = File.read(File.join(ROOT, "assets/js/code-copy.js"))
    runner = <<~JS
      const vm = require("node:vm");

      class Element {
        constructor(tagName, options = {}) {
          this.tagName = tagName.toUpperCase();
          this.className = options.className || "";
          this.textContent = options.textContent || "";
          this.children = [];
          this.dataset = {};
          this.attributes = {};
          this.listeners = {};
          this.disabled = false;
          this.classList = {
            add: (className) => {
              if (!this.className.split(/\s+/).includes(className)) {
                this.className = [this.className, className].filter(Boolean).join(" ");
              }
            }
          };
        }

        appendChild(child) {
          this.children.push(child);
          return child;
        }

        remove() {
          this.removed = true;
        }

        setAttribute(name, value) {
          this.attributes[name] = value;
        }

        addEventListener(name, callback) {
          this.listeners[name] = callback;
        }

        closest(selector) {
          let node = this;

          while (node) {
            if (
              selector === ".highlighter-rouge" &&
              node.className.split(/\s+/).includes("highlighter-rouge")
            ) {
              return node;
            }

            node = node.parentElement;
          }

          return null;
        }

        querySelector(selector) {
          return this.querySelectorAll(selector)[0] || null;
        }

        querySelectorAll(selector) {
          const matches = [];

          function visit(node) {
            if (selector === "pre code" && node.tagName === "CODE") {
              matches.push(node);
            } else if (
              selector === ".highlight" &&
              node.className.split(/\s+/).includes("highlight")
            ) {
              matches.push(node);
            } else if (selector === ".code-copy-button" && node.className === "code-copy-button") {
              matches.push(node);
            }

            node.children.forEach(visit);
          }

          this.children.forEach(visit);
          return matches;
        }
      }

      function codeBlock(wrapperClass, text) {
        const wrapper = new Element("div", { className: wrapperClass + " highlighter-rouge" });
        const block = new Element("div", { className: "highlight" });
        const pre = new Element("pre");
        const code = new Element("code", { textContent: text });
        pre.appendChild(code);
        block.appendChild(pre);
        wrapper.appendChild(block);
        return wrapper;
      }

      const commandBlock = codeBlock(
        "language-bash",
        "$ brew install ruby\\ninstalled output\\n$ bundle install\\n"
      );
      const textBlock = codeBlock("language-text", "> keep this quoted text\\n");
      const shellScriptBlock = codeBlock(
        "language-bash",
        "# script comment\\nbrew update\\nbrew install ruby\\n"
      );
      const heredocBlock = codeBlock(
        "language-bash",
        ["$ cat <<'EOF'", "hello", "EOF", "output", "$ printf done \\\\", "  now"].join("\\n") + "\\n"
      );
      const blocks = [commandBlock, textBlock, shellScriptBlock, heredocBlock];
      const copiedTexts = [];

      const document = {
        readyState: "complete",
        body: new Element("body"),
        addEventListener() {},
        createElement(tagName) {
          return new Element(tagName);
        },
        querySelectorAll(selector) {
          if (selector === ".highlighter-rouge") {
            return blocks;
          }
          return [];
        },
        execCommand() {
          return false;
        }
      };

      const window = {
        document,
        isSecureContext: true,
        setTimeout() {
          return 1;
        },
        clearTimeout() {}
      };

      const navigator = {
        clipboard: {
          writeText(text) {
            copiedTexts.push(text);
            return Promise.resolve();
          }
        }
      };

      const sandbox = {
        document,
        navigator,
        Promise,
        window
      };

      vm.runInNewContext(#{JSON.generate(code_copy_script)}, sandbox);

      const buttonLabels = blocks.map((block) => block.querySelector(".code-copy-button").textContent);
      blocks.forEach((block) => block.querySelector(".code-copy-button").listeners.click());

      Promise.resolve().then(() => {
        process.stdout.write(JSON.stringify({
          button_labels: buttonLabels,
          copied_texts: copiedTexts
        }));
      });
    JS

    stdout, stderr, status = Open3.capture3("node", "-", stdin_data: runner)

    assert status.success?, stderr

    JSON.parse(stdout)
  end
end
