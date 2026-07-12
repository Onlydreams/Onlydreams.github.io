$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "preflight.ps1")
$jekyllRunner = "load Gem.bin_path('jekyll', 'jekyll')"
& $env:ONLYDREAMS_RUBY "-rbundler/setup" "-e" $jekyllRunner "--" "serve" @args
exit $LASTEXITCODE
