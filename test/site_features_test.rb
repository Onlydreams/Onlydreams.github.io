# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "tmpdir"

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
    assert_includes script, "copyText(code.textContent)"
    assert_includes script, "code-copy-button"
    assert_includes script, "existingButtons"
    assert_includes script, "button.remove()"

    styles = read_scss_sources
    assert_includes styles, ".code-copy-button:focus-visible"
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

  def test_home_page_shows_excerpts_tags_and_updated_time
    html = read_site("index.html")
    tags_html = read_site("tags/index.html")

    assert_includes html, 'class="post-card-excerpt"'
    assert_includes html, 'class="post-card-tags"'
    assert_includes html, "/tags/#tag-codex"
    assert_includes tags_html, 'id="tag-codex"'
    assert_includes html, 'class="post-updated"'
    assert_includes html, "<time datetime="
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

    assert_includes html, 'class="related-posts"'
    assert_includes html, "相关文章"
    assert_includes html, "/posts/macos-claude-deepseek/"
    assert_includes html, '<span class="related-post-tags">'
    assert_includes html, "claude / deepseek / api"
  end

  def test_posts_render_giscus_comments
    html = read_site("posts/macos-claude-deepseek/index.html")

    assert_includes html, "https://giscus.app/client.js"
    assert_includes html, 'data-repo="Onlydreams/Onlydreams.github.io"'
    assert_includes html, 'data-category="Announcements"'
    assert_includes html, 'data-theme-light="https://onlydreams.github.io/assets/giscus-theme.css"'
    assert_includes html, 'data-theme-dark="https://onlydreams.github.io/assets/giscus-theme-dark.css"'
    assert_includes html, 'data-lang="zh-CN"'

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
          <url><loc>https://onlydreams.github.io/custom-post-path/</loc></url>
          <url><loc>https://other.example.com/ignored/</loc></url>
        </urlset>
      XML

      indexnow = IndexNow.new(
        "INDEXNOW_HOST" => "onlydreams.github.io",
        "EXPECTED_SITEMAP_PATH" => sitemap_path
      )

      assert_equal ["https://onlydreams.github.io/custom-post-path/"], indexnow.send(:expected_site_urls)
    end
  end

  def test_indexnow_workflow_builds_local_sitemap_before_waiting
    workflow = File.read(File.join(ROOT, ".github/workflows/indexnow.yml"))

    assert_includes workflow, "bundle exec jekyll build"
    assert_includes workflow, "EXPECTED_SITEMAP_PATH: _site/sitemap.xml"
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
end
