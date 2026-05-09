# frozen_string_literal: true

require "minitest/autorun"
require "json"

class SiteFeaturesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SITE = File.join(ROOT, "_site")

  def read_site(path)
    File.read(File.join(SITE, path))
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
    assert_includes html, 'href="#shell-环境变量"'
  end

  def test_code_copy_button_behavior_is_available
    script = File.read(File.join(ROOT, "assets/js/theme.js"))

    assert_includes script, "initCodeCopyButtons"
    assert_includes script, "navigator.clipboard.writeText"
    assert_includes script, "copyTextFallback"
    assert_includes script, "return copyTextFallback(text)"
    assert_includes script, "copyText(code.textContent)"
    assert_includes script, "code-copy-button"
    assert_includes script, "existingButtons"
    assert_includes script, "button.remove()"

    styles = File.read(File.join(ROOT, "assets/main.scss"))
    assert_includes styles, ".code-copy-button:focus-visible"
  end

  def test_search_page_and_index_are_available
    html = read_site("search/index.html")
    index = JSON.parse(read_site("search.json"))
    script = File.read(File.join(ROOT, "assets/js/theme.js"))

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
end
