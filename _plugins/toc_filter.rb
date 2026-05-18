# frozen_string_literal: true

require "cgi"
require "liquid"

module TocFilter
  HEADING_PATTERN = %r{<h([23])\b([^>]*)>(.*?)</h\1>}im
  ID_PATTERN = /\bid\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i

  def toc_from_html(html)
    TocFilter.toc_from_html(html)
  end

  def self.toc_from_html(html)
    sections = sections_from(html.to_s)

    return "" if sections.empty?

    render_toc(sections)
  end

  def self.sections_from(html)
    sections = []
    current_section = nil

    html.scan(HEADING_PATTERN) do |level, attrs, inner_html|
      item = {
        id: heading_id(attrs),
        text: heading_text(inner_html),
        children: []
      }
      next if item[:id].to_s.empty? || item[:text].to_s.empty?

      if level == "2"
        current_section = item
        sections << current_section
      elsif current_section
        current_section[:children] << item
      end
    end

    sections
  end
  private_class_method :sections_from

  def self.heading_id(attrs)
    match = attrs.to_s.match(ID_PATTERN)
    return nil unless match

    decode_html(match.captures.compact.first)
  end
  private_class_method :heading_id

  def self.heading_text(html)
    text = html.to_s
      .gsub(/<[^>]+>/, "")
      .gsub(/\s+/, " ")
      .strip

    decode_html(text)
  end
  private_class_method :heading_text

  def self.decode_html(value)
    normalized = value.to_s
      .gsub(/&nbsp;/i, "\u00A0")
      .gsub(/&mdash;/i, "\u2014")
      .gsub(/&ndash;/i, "\u2013")

    CGI.unescapeHTML(normalized)
  end
  private_class_method :decode_html

  def self.render_toc(sections)
    html = +"<aside class=\"post-toc\">\n"
    html << "  <h2 class=\"toc-title\">目录</h2>\n"
    html << "  <ul id=\"markdown-toc\">\n"

    sections.each do |section|
      html << toc_item(section)
    end

    html << "  </ul>\n"
    html << "</aside>\n"
  end
  private_class_method :render_toc

  def self.toc_item(item)
    html = +"    <li><a href=\"##{escape_attr(item[:id])}\">#{escape_text(item[:text])}</a>"
    if item[:children].any?
      html << "\n      <ul>\n"
      item[:children].each do |child|
        html << "        <li><a href=\"##{escape_attr(child[:id])}\">#{escape_text(child[:text])}</a></li>\n"
      end
      html << "      </ul>\n"
      html << "    </li>\n"
    else
      html << "</li>\n"
    end
    html
  end
  private_class_method :toc_item

  def self.escape_attr(value)
    CGI.escapeHTML(value.to_s)
  end
  private_class_method :escape_attr

  def self.escape_text(value)
    CGI.escapeHTML(value.to_s)
  end
  private_class_method :escape_text
end

Liquid::Template.register_filter(TocFilter)
