# frozen_string_literal: true

require "date"
require "minitest/autorun"
require "tmpdir"
require "time"
require "yaml"

require File.join(File.expand_path("..", __dir__), "bin", "embed_article_scripts.rb")

class ContentHealthTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  POST_PATHS = Dir[File.join(ROOT, "_posts/*.md")].sort.freeze
  ENGLISH_POST_PATHS = Dir[File.join(ROOT, "_english_posts/*.md")].sort.freeze
  REQUIRED_FRONT_MATTER_KEYS = %w[layout title date categories tags status].freeze
  REQUIRED_ENGLISH_FRONT_MATTER_KEYS = (REQUIRED_FRONT_MATTER_KEYS + %w[lang translation_key]).freeze
  REQUIRED_STATUS_KEYS = %w[label verified environment risk].freeze
  ALLOWED_STATUS_LABELS = ["当前可用", "待复核", "已失效"].freeze
  ALLOWED_CATEGORIES = ["AI", "开发工具", "网络与代理", "浏览器", "体育技术"].freeze
  ALLOWED_ENGLISH_CATEGORIES = ["AI", "Developer Tools", "Browsers", "Sports Technology"].freeze
  FORBIDDEN_TAG_ALIASES = { "agents" => "agent" }.freeze
  SENSITIVE_PATTERNS = {
    "GitHub noreply email" => /users\.noreply\.github\.com/i,
    "OpenAI-style API key" => /\bsk-[A-Za-z0-9_-]{20,}\b/,
    "GitHub personal access token" => /\bghp_[A-Za-z0-9_]{20,}\b/,
    "Slack token" => /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/,
    "raw bearer token" => /Authorization:\s*Bearer\s+(?!<TOKEN>|YOUR_TOKEN|set-your-secret)[A-Za-z0-9._~+\/=-]{12,}/i
  }.freeze

  def posts
    load_articles(POST_PATHS)
  end

  def english_posts
    load_articles(ENGLISH_POST_PATHS)
  end

  def load_articles(paths)
    paths.map do |path|
      front_matter, body = split_front_matter(path)
      {
        path: path,
        relative_path: path.delete_prefix("#{ROOT}/"),
        front_matter: front_matter,
        body: body
      }
    end
  end

  def test_selected_english_posts_have_complete_front_matter
    assert_equal 9, english_posts.size

    english_posts.each do |post|
      missing_keys = REQUIRED_ENGLISH_FRONT_MATTER_KEYS.reject do |key|
        value = post[:front_matter][key]
        value.respond_to?(:empty?) ? !value.empty? : !value.nil?
      end

      assert_empty missing_keys, "#{post[:relative_path]} missing front matter keys: #{missing_keys.join(", ")}"
      assert_equal "post", post[:front_matter]["layout"]
      assert_equal "en", post[:front_matter]["lang"]
      assert_operator coerce_time(post[:front_matter]["date"]), :<=, Time.now

      categories = Array(post[:front_matter]["categories"])
      assert_includes 1..2, categories.size
      categories.each do |category|
        assert_includes ALLOWED_ENGLISH_CATEGORIES, category
      end

      status = post[:front_matter]["status"] || {}
      REQUIRED_STATUS_KEYS.each do |key|
        refute_empty status[key].to_s.strip, "#{post[:relative_path]} missing status.#{key}"
      end
      assert_includes ALLOWED_STATUS_LABELS, status["label"]
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, status["verified"].to_s)
    end
  end

  def test_selected_translations_have_unique_one_to_one_keys
    english_by_key = english_posts.to_h { |post| [post[:front_matter]["translation_key"], post] }
    chinese_translations = posts.select { |post| post[:front_matter]["translation_key"] }
    chinese_by_key = chinese_translations.to_h { |post| [post[:front_matter]["translation_key"], post] }
    translation_map = YAML.load_file(File.join(ROOT, "_data", "translations.yml"))

    assert_equal english_posts.size, english_by_key.size
    assert_equal chinese_translations.size, chinese_by_key.size
    assert_equal english_by_key.keys.sort, chinese_by_key.keys.sort
    assert_equal english_by_key.keys.sort, (translation_map.keys - ["home"]).sort

    chinese_translations.each do |post|
      key = post[:front_matter]["translation_key"]
      chinese_slug = File.basename(post[:path], ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
      english_slug = File.basename(english_by_key.fetch(key)[:path], ".md")

      assert_equal "zh-CN", post[:front_matter]["lang"], "#{post[:relative_path]} must declare lang: zh-CN"
      assert_equal "/posts/#{chinese_slug}/", translation_map.dig(key, "zh")
      assert_equal "/en/posts/#{english_slug}/", translation_map.dig(key, "en")
    end
  end

  def test_all_posts_have_required_front_matter
    posts.each do |post|
      missing_keys = REQUIRED_FRONT_MATTER_KEYS.reject do |key|
        value = post[:front_matter][key]
        value.respond_to?(:empty?) ? !value.empty? : !value.nil?
      end

      assert_empty missing_keys, "#{post[:relative_path]} missing front matter keys: #{missing_keys.join(", ")}"
      assert_equal "post", post[:front_matter]["layout"], "#{post[:relative_path]} must use layout: post"
    end
  end

  def test_post_dates_are_not_future_dates
    now = Time.now

    posts.each do |post|
      date = coerce_time(post[:front_matter]["date"])

      assert_operator date, :<=, now, "#{post[:relative_path]} has future date #{date}"
    end
  end

  def test_status_metadata_is_complete_and_consistent
    posts.each do |post|
      status = post[:front_matter]["status"] || {}
      missing_keys = REQUIRED_STATUS_KEYS.reject do |key|
        value = status[key]
        value.respond_to?(:strip) ? !value.strip.empty? : !value.nil?
      end

      assert_empty missing_keys, "#{post[:relative_path]} missing status keys: #{missing_keys.join(", ")}"
      assert_includes ALLOWED_STATUS_LABELS, status["label"], "#{post[:relative_path]} has unsupported status label #{status["label"].inspect}"

      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, status["verified"].to_s, "#{post[:relative_path]} must use an ISO verified date")
    end
  end

  def test_series_posts_have_matching_series_order
    posts.each do |post|
      series = Array(post[:front_matter]["series"])
      next if series.empty?

      series_order = post[:front_matter]["series_order"] || {}
      missing_order = series.reject { |series_key| series_order.key?(series_key) }

      assert_empty missing_order, "#{post[:relative_path]} missing series_order keys: #{missing_order.join(", ")}"
    end
  end

  def test_categories_use_the_stable_taxonomy
    posts.each do |post|
      categories = Array(post[:front_matter]["categories"])

      assert_includes 1..2, categories.size, "#{post[:relative_path]} must use one or two categories"
      categories.each do |category|
        assert_includes ALLOWED_CATEGORIES, category, "#{post[:relative_path]} has unsupported category #{category.inspect}"
      end
    end
  end

  def test_tags_do_not_use_known_aliases
    posts.each do |post|
      Array(post[:front_matter]["tags"]).each do |tag|
        refute FORBIDDEN_TAG_ALIASES.key?(tag), "#{post[:relative_path]} should use tag #{FORBIDDEN_TAG_ALIASES[tag].inspect} instead of #{tag.inspect}"
      end
    end
  end

  def test_public_posts_do_not_contain_common_secret_patterns
    (posts + english_posts).each do |post|
      text = [post[:front_matter].to_s, post[:body]].join("\n")

      SENSITIVE_PATTERNS.each do |name, pattern|
        refute_match pattern, text, "#{post[:relative_path]} appears to contain #{name}"
      end
    end
  end

  def test_embedded_edge_repair_script_matches_repo_source
    articles = posts + english_posts
    expected = EmbedArticleScripts.escaped_script(
      File.join(ROOT, "tools", "repair-edge-renderer.ps1")
    )

    [
      "_posts/2026-07-25-microsoft-edge-blank-pages-renderer-state-repair.md",
      "_english_posts/microsoft-edge-blank-pages-renderer-state-repair.md"
    ].each do |relative_path|
      article = articles.find { |candidate| candidate[:relative_path] == relative_path }
      refute_nil article, "#{relative_path} must exist"

      match = article[:body].match(%r{<pre><code class="language-powershell">(.*?)</code></pre>}m)
      refute_nil match, "#{relative_path} must embed the script in a <pre><code> block"

      assert_equal expected, match[1].gsub("\r\n", "\n"),
        "embedded script in #{relative_path} must match tools/repair-edge-renderer.ps1 byte for byte; " \
        "run `ruby bin/embed_article_scripts.rb` to re-embed"
    end
  end

  def test_article_script_embedding_preserves_backslash_sequences_literally
    Dir.mktmpdir do |directory|
      script_path = File.join(directory, "sample.ps1")
      article_path = File.join(directory, "article.md")
      script = '$path.TrimEnd("\\") + "\\"' + "\n"
      article = "before\n<div>\n#{EmbedArticleScripts::OPEN_BLOCK}old#{EmbedArticleScripts::CLOSE_BLOCK}\n</div>\n</details>\nafter\n"
      File.binwrite(script_path, script)
      File.binwrite(article_path, article)

      EmbedArticleScripts.embed_one!(article_path: article_path, script_path: script_path)

      expected = "before\n<div>\n#{EmbedArticleScripts.embedded_block(script_path)}\n</div>\n</details>\nafter\n"
      assert_equal expected, File.binread(article_path)
    end
  end

  def test_edge_repair_script_guards_the_complete_update_switch
    script = File.read(File.join(ROOT, "tools", "repair-edge-renderer.ps1"))

    backup_index = script.index("Copy-EdgeBackup -UserDataPath")
    update_index = script.index("winget install --id Microsoft.Edge")

    refute_nil backup_index
    refute_nil update_index
    assert_operator backup_index, :<, update_index,
      "the complete User Data backup must finish before the repair invokes Edge Update"
    assert_includes script, "version_switch_complete"
    assert_includes script, "OldProductVersion"
    assert_includes script, "NewMsedgeExists"
    assert_includes script, "停止修改 Local State"
    assert_includes script, "firstColdStartRenderers"
    assert_includes script, "secondColdStartRenderers"
    assert_includes script, "Remove-TemporaryDirectory"
    assert_includes script, "Test-EdgeEntrypointTargets"
    assert_includes script, "VersionDirectories"
    assert_includes script, "pageConfirmation"
    assert_includes script, "完整修复验收完成"
  end

  def test_edge_repair_articles_require_version_and_renderer_convergence
    expectations = {
      "_posts/2026-07-25-microsoft-edge-blank-pages-renderer-state-repair.md" =>
        ["151.0.4129.107", "`opv` 必须清空", "连续两次冷启动", "输入 `YES`"],
      "_english_posts/microsoft-edge-blank-pages-renderer-state-repair.md" =>
        ["151.0.4129.107", "`opv` must be empty", "two consecutive cold starts", "entering `YES`"]
    }

    articles = posts + english_posts
    expectations.each do |relative_path, required_texts|
      article = articles.find { |candidate| candidate[:relative_path] == relative_path }
      refute_nil article, "#{relative_path} must exist"

      required_texts.each do |required_text|
        assert_includes article[:body], required_text,
          "#{relative_path} must document the complete update-switch acceptance test"
      end
    end
  end

  private

  def split_front_matter(path)
    content = File.read(path)
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)

    refute_nil match, "#{path.delete_prefix("#{ROOT}/")} must start with YAML front matter"

    [
      YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true),
      match[2]
    ]
  end

  def coerce_time(value)
    case value
    when Time
      value
    when Date
      value.to_time
    else
      Time.parse(value.to_s)
    end
  end
end
