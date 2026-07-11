$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")
Invoke-ProjectBundle exec jekyll serve @args
