$ErrorActionPreference = "Stop"

bundle exec jekyll build
ruby test/site_features_test.rb
