$ErrorActionPreference = "Stop"

bundle exec jekyll build
bundle exec ruby test/site_features_test.rb
