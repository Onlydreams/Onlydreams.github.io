$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")

function Invoke-Checked {
  param([scriptblock]$Command)

  & $Command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Invoke-Checked { & $env:ONLYDREAMS_RUBY "-rbundler/setup" "-S" "jekyll" "build" }
Invoke-Checked { & $env:ONLYDREAMS_RUBY "-rbundler/setup" "test/site_features_test.rb" }
Invoke-Checked { & $env:ONLYDREAMS_RUBY "-rbundler/setup" "test/content_health_test.rb" }
