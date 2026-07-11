$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")

Invoke-ProjectBundle config set --local path vendor/bundle
Invoke-ProjectBundle install
