$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\tools\repair-edge-renderer.ps1")

$assertionCount = 0

function Assert-Equal {
  param(
    $Expected,
    $Actual,
    [string]$Message
  )

  $script:assertionCount++
  if ($Expected -ne $Actual) {
    throw "$Message`nExpected: $Expected`nActual: $Actual"
  }
}

function Assert-Throws {
  param(
    [scriptblock]$Action,
    [string]$Message
  )

  $script:assertionCount++
  try {
    & $Action
  } catch {
    return
  }
  throw "$Message`nExpected the action to throw."
}

$currentVersion = "151.0.4129.107"
$completeVersionState = @{
  LauncherVersion = $currentVersion
  CurrentVersion = $currentVersion
  ProductVersion = $currentVersion
  OldProductVersion = ""
  NewMsedgeExists = $false
  VersionDirectories = @($currentVersion)
}

Assert-Equal $true (Test-EdgeVersionSwitchValues @completeVersionState) `
  "A fully converged Edge version state must pass."

$failureCases = @(
  @{ Name = "launcher mismatch"; Values = @{ LauncherVersion = "151.0.4129.72" } },
  @{ Name = "registered version mismatch"; Values = @{ ProductVersion = "151.0.4129.72" } },
  @{ Name = "old product version remains"; Values = @{ OldProductVersion = "151.0.4129.72" } },
  @{ Name = "new_msedge remains"; Values = @{ NewMsedgeExists = $true } },
  @{ Name = "old version directory remains"; Values = @{ VersionDirectories = @("151.0.4129.107", "151.0.4129.72") } },
  @{ Name = "only old version directory remains"; Values = @{ VersionDirectories = @("151.0.4129.72") } }
)

foreach ($failureCase in $failureCases) {
  $values = $completeVersionState.Clone()
  foreach ($key in $failureCase.Values.Keys) {
    $values[$key] = $failureCase.Values[$key]
  }
  Assert-Equal $false (Test-EdgeVersionSwitchValues @values) `
    "Version convergence must reject: $($failureCase.Name)."
}

$launcher = Join-Path $env:TEMP "Edge\Application\msedge.exe"
$validEntrypoints = @(
  [pscustomobject]@{ Type = "Registry"; Location = "app-path"; Target = "`"$launcher`" --single-argument %1" },
  [pscustomobject]@{ Type = "Shortcut"; Location = "start-menu"; Target = $launcher }
)
$validEntrypointState = Test-EdgeEntrypointTargets -Launcher $launcher -Entrypoints $validEntrypoints
Assert-Equal $true $validEntrypointState.IsComplete "Matching registry and shortcut targets must pass."
Assert-Equal 2 $validEntrypointState.CheckedCount "Every supplied entry point must be counted."

$staleEntrypoints = @(
  [pscustomobject]@{ Type = "Registry"; Location = "app-path"; Target = "`"$launcher`"" },
  [pscustomobject]@{ Type = "Shortcut"; Location = "desktop"; Target = (Join-Path $env:TEMP "Edge\Application\151.0.4129.72\msedge.exe") }
)
$staleEntrypointState = Test-EdgeEntrypointTargets -Launcher $launcher -Entrypoints $staleEntrypoints
Assert-Equal $false $staleEntrypointState.IsComplete "A version-specific stale shortcut must fail."
Assert-Equal 1 $staleEntrypointState.StaleEntries.Count "The stale target must be reported."
Assert-Equal $false (Test-EdgeEntrypointTargets -Launcher $launcher -Entrypoints @()).IsComplete `
  "An empty entry-point set must not claim success."

$validTemporaryChild = Join-Path $env:TEMP "edge-renderer-test-child"
Assert-Equal ([System.IO.Path]::GetFullPath($validTemporaryChild)) `
  (Assert-TemporaryDirectoryPath -Path $validTemporaryChild) `
  "A child of the system temporary directory must pass."

Assert-Throws { Assert-TemporaryDirectoryPath -Path $env:TEMP } `
  "The temporary root itself must not be accepted for recursive cleanup."
Assert-Throws { Assert-TemporaryDirectoryPath -Path ([System.IO.Path]::GetDirectoryName($env:TEMP)) } `
  "A parent of the temporary directory must be rejected."
Assert-Throws { Assert-TemporaryDirectoryPath -Path ($env:TEMP + "-outside") } `
  "A sibling path sharing the temporary prefix must be rejected."

Write-Host "Edge repair script behavior: $assertionCount assertions passed."
