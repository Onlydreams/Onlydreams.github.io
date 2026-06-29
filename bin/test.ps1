$ErrorActionPreference = "Stop"

function Invoke-Checked {
  param([scriptblock]$Command)

  & $Command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Invoke-Checked { bundle exec jekyll build }
Invoke-Checked { bundle exec ruby test/site_features_test.rb }
Invoke-Checked { bundle exec ruby test/content_health_test.rb }
