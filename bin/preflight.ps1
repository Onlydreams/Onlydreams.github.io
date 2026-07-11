[CmdletBinding()]
param(
  [switch]$AllowMissingBundler
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$requiredRuby = (Get-Content -LiteralPath (Join-Path $repoRoot ".ruby-version") -Raw).Trim()
$bundlerVersion = (
  Get-Content -LiteralPath (Join-Path $repoRoot "Gemfile.lock") |
    Select-String -Pattern '^BUNDLED WITH$' -Context 0, 1 |
    ForEach-Object { $_.Context.PostContext[0].Trim() } |
    Select-Object -First 1
)

if (-not $bundlerVersion) {
  throw "Onlydreams toolchain error: could not read the Bundler version from Gemfile.lock."
}

$rubyCandidates = @()
if ($env:ONLYDREAMS_RUBY) {
  $rubyCandidates += $env:ONLYDREAMS_RUBY
}

$pathRuby = Get-Command ruby -ErrorAction SilentlyContinue
if ($pathRuby) {
  $rubyCandidates += $pathRuby.Source
}

# RubyInstaller can live on any local drive. Scan the conventional Ruby*
# locations so a coexisting newer Ruby in PATH cannot silently take over.
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
  Join-Path $_.Root 'Ruby*\bin\ruby.exe'
} | ForEach-Object {
  Get-ChildItem -Path $_ -File -ErrorAction SilentlyContinue
} | ForEach-Object {
  $rubyCandidates += $_.FullName
}

$rubyExecutable = $null
foreach ($candidate in ($rubyCandidates | Select-Object -Unique)) {
  if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
    continue
  }

  $version = & $candidate --version
  if ($LASTEXITCODE -eq 0 -and $version -match "^ruby\s+$([regex]::Escape($requiredRuby))(?=p|\s|$)") {
    $rubyExecutable = $candidate
    break
  }
}

if (-not $rubyExecutable) {
  throw "Onlydreams toolchain error: Ruby $requiredRuby is required. Install it, activate your version manager, or set ONLYDREAMS_RUBY to its ruby.exe path."
}

$rubyDirectory = Split-Path -Parent $rubyExecutable
$bundleCandidates = @(
  (Join-Path $rubyDirectory "bundle.bat"),
  (Join-Path $rubyDirectory "bundle")
)
$gemCandidates = @(
  (Join-Path $rubyDirectory "gem.bat"),
  (Join-Path $rubyDirectory "gem")
)
$bundleExecutable = $bundleCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
$gemExecutable = $gemCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if (-not $bundleExecutable -or -not $gemExecutable) {
  throw "Onlydreams toolchain error: bundle or gem was not found next to $rubyExecutable."
}

# Keep this scoped to the invoking PowerShell process. The repository-local
# .bundle/config and selected Ruby must win over machine-wide gem paths.
Remove-Item Env:BUNDLE_PATH -ErrorAction SilentlyContinue
Remove-Item Env:BUNDLE_GEMFILE -ErrorAction SilentlyContinue
Remove-Item Env:BUNDLE_BIN_PATH -ErrorAction SilentlyContinue
Remove-Item Env:GEM_HOME -ErrorAction SilentlyContinue
Remove-Item Env:GEM_PATH -ErrorAction SilentlyContinue
Remove-Item Env:RUBYOPT -ErrorAction SilentlyContinue
$env:PATH = "$rubyDirectory;$env:PATH"
$env:ONLYDREAMS_RUBY = $rubyExecutable
$env:ONLYDREAMS_BUNDLE = $bundleExecutable
$env:ONLYDREAMS_GEM = $gemExecutable
$env:ONLYDREAMS_BUNDLER_VERSION = $bundlerVersion

& $bundleExecutable ("_{0}_" -f $bundlerVersion) --version | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Onlydreams toolchain error: Bundler $bundlerVersion is unavailable for Ruby $requiredRuby. Reinstall the exact Ruby version from .ruby-version."
}

function Invoke-ProjectBundle {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

  & $env:ONLYDREAMS_BUNDLE ("_{0}_" -f $env:ONLYDREAMS_BUNDLER_VERSION) @Arguments
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
