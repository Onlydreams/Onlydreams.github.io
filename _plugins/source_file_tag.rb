# frozen_string_literal: true

require "cgi"

module Jekyll
  class SourceFileTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @relative_path = markup.strip
    end

    def render(context)
      site_root = File.expand_path(context.registers.fetch(:site).source)
      source_path = File.expand_path(@relative_path, site_root)

      unless source_path.start_with?("#{site_root}#{File::SEPARATOR}") && File.file?(source_path)
        raise ArgumentError, "source_file must reference an existing file inside the site source"
      end

      CGI.escapeHTML(File.read(source_path))
    end
  end
end

Liquid::Template.register_tag("source_file", Jekyll::SourceFileTag)
