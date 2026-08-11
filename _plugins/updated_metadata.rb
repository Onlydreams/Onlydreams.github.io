# frozen_string_literal: true

Jekyll::Hooks.register :documents, :pre_render do |document|
  updated = document.data["updated"]
  next if updated.nil? || updated.to_s.strip.empty?

  # Jekyll SEO Tag, jekyll-feed, and jekyll-sitemap read this standard key.
  document.data["last_modified_at"] ||= updated
end
