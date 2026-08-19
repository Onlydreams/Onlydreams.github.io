# frozen_string_literal: true

# One-command helper: re-embeds the canonical script into the articles that
# display its full source. The articles must stay byte-for-byte in sync with
# tools/repair-edge-renderer.ps1 after LF line-ending normalization (git
# stores all repo files as LF; CRLF in Windows working trees is a checkout
# artifact and this repo's working tree is already mixed); the test in
# test/content_health_test.rb enforces that contract, and both share this
# module so the escaping logic cannot drift.
#
# Usage:
#   ruby bin/embed_article_scripts.rb
#
# Idempotent: running it again after the articles are already in sync is a
# no-op. Writes are binary with explicit LF normalization, so whenever the
# helper rewrites an article it writes the same LF bytes on Windows and Unix,
# independent of Ruby's platform text-mode newline translation.

module EmbedArticleScripts
  ROOT = File.expand_path("..", __dir__)
  SCRIPT_PATH = File.join(ROOT, "tools", "repair-edge-renderer.ps1")
  ARTICLE_PATHS = [
    File.join(ROOT, "_posts", "2026-07-25-microsoft-edge-blank-pages-renderer-state-repair.md"),
    File.join(ROOT, "_english_posts", "microsoft-edge-blank-pages-renderer-state-repair.md")
  ].freeze
  OPEN_BLOCK = '<pre><code class="language-powershell">'
  CLOSE_BLOCK = "</code></pre>"

  module_function

  # Read raw bytes and expose them as UTF-8 with LF line endings, so escaping
  # and comparisons are identical on every platform.
  def read_lf(path)
    File.binread(path).force_encoding("UTF-8").gsub("\r\n", "\n")
  end

  # Explicit mirror of CGI.escapeHTML so the article block and the
  # byte-for-byte test always agree. Escape "&" first so entities introduced
  # by later substitutions are never double-escaped.
  def escape_html(text)
    text
      .gsub("&", "&amp;")
      .gsub("<", "&lt;")
      .gsub(">", "&gt;")
      .gsub('"', "&quot;")
      .gsub("'", "&#39;")
  end

  def escaped_script(script_path)
    escape_html(read_lf(script_path))
  end

  def embedded_block(script_path)
    "#{OPEN_BLOCK}#{escaped_script(script_path)}#{CLOSE_BLOCK}"
  end

  def embed!(article_paths: ARTICLE_PATHS, script_path: SCRIPT_PATH)
    article_paths.map { |path| embed_one!(article_path: path, script_path: script_path) }
  end

  def embed_one!(article_path:, script_path:)
    article = read_lf(article_path)
    unless article.include?(OPEN_BLOCK) && article.include?(CLOSE_BLOCK)
      raise "embedded block markers not found in #{article_path}"
    end

    block = embedded_block(script_path)
    new_article = article.sub(
      %r{#{Regexp.escape(OPEN_BLOCK)}.*?#{Regexp.escape(CLOSE_BLOCK)}}m,
      block
    )

    return "already in sync: #{article_path}" if new_article == article

    File.binwrite(article_path, new_article)
    "re-embedded #{script_path} into #{article_path}"
  end
end

if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)
  puts EmbedArticleScripts.embed!
end
