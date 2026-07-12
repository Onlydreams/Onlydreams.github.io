$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")

function Invoke-Checked {
  param([scriptblock]$Command)

  & $Command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Invoke-Checked { Invoke-ProjectBundle exec jekyll build }
Invoke-Checked { Invoke-ProjectBundle exec ruby test/site_features_test.rb }
Invoke-Checked { Invoke-ProjectBundle exec ruby test/content_health_test.rb }
