#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "rexml/document"
require "timeout"
require "uri"

class IndexNow
  RETRY_COUNT = 30
  RETRY_DELAY_SECONDS = 10
  SITEMAP_LOC_XPATH = "//*[local-name() = \"loc\"]"

  def initialize(env)
    @env = env
    @host = env.fetch("INDEXNOW_HOST")
  end

  def wait
    key = @env.fetch("INDEXNOW_KEY")
    key_uri = URI(@env.fetch("KEY_URL"))
    sitemap_uri = URI(@env.fetch("SITEMAP_URL"))
    expected_urls = expected_site_urls

    RETRY_COUNT.times do |index|
      key_live = fetch_body(key_uri).strip == key
      sitemap_urls = site_urls_from(fetch_body(sitemap_uri))
      missing_urls = expected_urls - sitemap_urls

      if key_live && missing_urls.empty?
        puts "Key file and sitemap are live."
        return
      end

      puts "Deployment not ready, retrying in #{RETRY_DELAY_SECONDS}s (#{index + 1}/#{RETRY_COUNT})"
      puts "Key file live: #{key_live}"
      puts "Missing sitemap URLs: #{missing_urls.join(", ")}" unless missing_urls.empty?
      sleep RETRY_DELAY_SECONDS
    end

    abort "IndexNow key file or sitemap was not updated in time."
  end

  def submit
    sitemap_uri = URI(@env.fetch("SITEMAP_URL"))
    urls = site_urls_from(fetch_body!(sitemap_uri))

    abort "No URLs found in #{sitemap_uri}" if urls.empty?

    payload = {
      host: @host,
      key: @env.fetch("INDEXNOW_KEY"),
      keyLocation: @env.fetch("INDEXNOW_KEY_LOCATION"),
      urlList: urls
    }

    endpoint = URI(@env.fetch("INDEXNOW_ENDPOINT"))
    request = Net::HTTP::Post.new(endpoint)
    request["Content-Type"] = "application/json; charset=utf-8"
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: true) do |http|
      http.request(request)
    end

    puts "Submitted #{payload[:urlList].size} URLs to IndexNow"
    puts "IndexNow response: #{response.code} #{response.message}"

    return if ["200", "202"].include?(response.code)

    warn response.body
    exit 1
  end

  private

  def expected_site_urls
    sitemap_path = @env.fetch("EXPECTED_SITEMAP_PATH", "_site/sitemap.xml")
    abort "Expected sitemap not found at #{sitemap_path}" unless File.file?(sitemap_path)

    site_urls_from(File.read(sitemap_path)).sort
  end

  def site_urls_from(xml)
    sitemap_urls_from(xml).select do |url|
      url.start_with?("https://#{@host}/")
    end.uniq
  end

  def fetch_body(uri)
    fetch_body!(uri)
  rescue SocketError => e
    warn "Network name resolution failed for #{uri.host}: #{e.message}"
    ""
  rescue SystemCallError, IOError, Timeout::Error, Net::HTTPError => e
    warn "Could not fetch #{uri}: #{e.class}: #{e.message}"
    ""
  end

  def fetch_body!(uri)
    response = Net::HTTP.get_response(uri)
    return response.body if response.is_a?(Net::HTTPSuccess)

    raise Net::HTTPError.new("HTTP #{response.code} #{response.message}", response)
  end

  def sitemap_urls_from(xml)
    doc = REXML::Document.new(xml)
    urls = []

    REXML::XPath.each(doc, SITEMAP_LOC_XPATH) do |loc|
      urls << loc.text.to_s.strip
    end

    urls
  rescue REXML::ParseException
    []
  end
end

def main(argv)
  case argv.fetch(0, nil)
  when "wait"
    IndexNow.new(ENV).wait
  when "submit"
    IndexNow.new(ENV).submit
  else
    abort "Usage: ruby .github/scripts/indexnow.rb wait|submit"
  end
end

main(ARGV) if $PROGRAM_NAME == __FILE__
