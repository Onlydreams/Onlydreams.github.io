$ErrorActionPreference = "Stop"

bundle exec jekyll build
bundle exec ruby test/site_features_test.rb
bundle exec ruby test/content_health_test.rb
