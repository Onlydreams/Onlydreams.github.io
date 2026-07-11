$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")

Invoke-ProjectBundle exec jekyll build
Invoke-ProjectBundle exec ruby test/site_features_test.rb
Invoke-ProjectBundle exec ruby test/content_health_test.rb
