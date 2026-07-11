$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")
& $env:ONLYDREAMS_RUBY "-rbundler/setup" "-S" "jekyll" "serve" @args
exit $LASTEXITCODE
