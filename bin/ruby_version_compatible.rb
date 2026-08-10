# frozen_string_literal: true

require "rubygems/version"

module OnlydreamsRubyVersion
  module_function

  def compatible?(required:, actual:)
    required_version = Gem::Version.new(required)
    actual_version = Gem::Version.new(actual)

    actual_version.segments.first(2) == required_version.segments.first(2) &&
      actual_version >= required_version
  rescue ArgumentError, TypeError
    false
  end
end

if $PROGRAM_NAME == __FILE__
  required_version = ARGV.fetch(0) do
    abort "usage: ruby ruby_version_compatible.rb REQUIRED_VERSION"
  end

  exit OnlydreamsRubyVersion.compatible?(required: required_version, actual: RUBY_VERSION)
end
