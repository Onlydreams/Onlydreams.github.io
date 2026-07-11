$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1") -AllowMissingBundler

$bundlerInstalled = & $env:ONLYDREAMS_GEM list bundler -i -v $env:ONLYDREAMS_BUNDLER_VERSION
if ($LASTEXITCODE -ne 0) {
  & $env:ONLYDREAMS_GEM install bundler --no-document --version $env:ONLYDREAMS_BUNDLER_VERSION
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Invoke-ProjectBundle config set --local path vendor/bundle
Invoke-ProjectBundle install
