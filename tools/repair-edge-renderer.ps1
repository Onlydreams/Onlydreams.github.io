[CmdletBinding()]
param(
  [switch]$Repair,
  [switch]$SkipUpdate
)

$ErrorActionPreference = "Stop"

function Write-Status {
  param([string]$Message)
  Write-Host "[Edge renderer repair] $Message"
}

function Get-EdgePaths {
  $applicationDirectory = Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application"
  $launcher = Join-Path $applicationDirectory "msedge.exe"
  $userData = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data"
  $localState = Join-Path $userData "Local State"

  if (-not (Test-Path -LiteralPath $launcher)) {
    throw "找不到 Edge 启动文件：$launcher"
  }
  if (-not (Test-Path -LiteralPath $localState)) {
    throw "找不到 Edge Local State，停止处理。"
  }

  $versionDirectories = @(
    Get-ChildItem -LiteralPath $applicationDirectory -Directory |
      Where-Object { $_.Name -match "^\d+\.\d+\.\d+\.\d+$" } |
      Sort-Object { [version]$_.Name } -Descending
  )
  $currentVersionDirectory = $versionDirectories | Select-Object -First 1
  if (-not $currentVersionDirectory) {
    throw "找不到 Edge 版本目录，停止处理。"
  }

  $currentBinary = Join-Path $currentVersionDirectory.FullName "msedge.exe"
  if (-not (Test-Path -LiteralPath $currentBinary)) {
    throw "找不到当前版本 Edge 二进制，停止处理。"
  }

  [pscustomobject]@{
    ApplicationDirectory = $applicationDirectory
    Launcher = $launcher
    CurrentBinary = $currentBinary
    UserData = $userData
    LocalState = $localState
  }
}

function Get-RendererCount {
  param([string]$ProfilePath)

  $processes = @(
    Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
      Where-Object { $_.CommandLine -like "*$ProfilePath*" }
  )
  [pscustomobject]@{
    ProcessCount = $processes.Count
    RendererCount = @($processes | Where-Object { $_.CommandLine -match "--type=renderer" }).Count
    ProcessIds = @($processes.ProcessId)
  }
}

function Stop-ProfileEdge {
  param([string]$ProfilePath)

  $result = Get-RendererCount -ProfilePath $ProfilePath
  if ($result.ProcessIds.Count -gt 0) {
    Stop-Process -Id $result.ProcessIds -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
  }
}

function Test-ProfileRenderer {
  param(
    [string]$EdgeBinary,
    [string]$ProfilePath
  )

  Start-Process -FilePath $EdgeBinary -ArgumentList @(
    "--user-data-dir=$ProfilePath",
    "--no-first-run",
    "--disable-extensions",
    "edge://settings"
  )
  Start-Sleep -Seconds 6

  try {
    Get-RendererCount -ProfilePath $ProfilePath
  } finally {
    Stop-ProfileEdge -ProfilePath $ProfilePath
  }
}

function Copy-EdgeBackup {
  param([string]$UserDataPath)

  $backupBase = Join-Path $env:LOCALAPPDATA "Edge-Recovery"
  $backupRoot = Join-Path $backupBase ("Edge-User-Data-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
  New-Item -ItemType Directory -Path $backupBase -Force | Out-Null

  & robocopy $UserDataPath $backupRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP
  if ($LASTEXITCODE -ge 8) {
    throw "Edge 用户数据备份失败，Robocopy exit code: $LASTEXITCODE"
  }

  $criticalFiles = @("Local State", "Default\Bookmarks", "Default\History", "Default\Login Data", "Default\Network\Cookies", "Default\Preferences")
  foreach ($relativePath in $criticalFiles) {
    $source = Join-Path $UserDataPath $relativePath
    $backup = Join-Path $backupRoot $relativePath
    if ((Test-Path -LiteralPath $source) -and ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash)) {
      throw "备份校验失败：$relativePath"
    }
  }

  $backupRoot
}

function Remove-MitigationManager {
  param([string]$LocalStatePath)

  $state = Get-Content -LiteralPath $LocalStatePath -Raw | ConvertFrom-Json
  if (-not $state.edge -or -not ($state.edge.PSObject.Properties.Name -contains "mitigation_manager")) {
    throw "edge.mitigation_manager 不存在，停止处理。"
  }
  $state.edge.PSObject.Properties.Remove("mitigation_manager")
  $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($LocalStatePath, ($state | ConvertTo-Json -Depth 100 -Compress), $utf8WithoutBom)

  $validated = Get-Content -LiteralPath $LocalStatePath -Raw | ConvertFrom-Json
  if ($validated.edge.PSObject.Properties.Name -contains "mitigation_manager") {
    throw "验证失败：临时文件中的目标对象仍然存在。"
  }
}

$paths = Get-EdgePaths
$launcherVersion = (Get-Item -LiteralPath $paths.Launcher).VersionInfo.FileVersion
$currentVersion = (Get-Item -LiteralPath $paths.CurrentBinary).VersionInfo.FileVersion
$state = Get-Content -LiteralPath $paths.LocalState -Raw | ConvertFrom-Json
$manager = $state.edge.mitigation_manager

if (-not $Repair) {
  [pscustomobject]@{
    launcher_version = $launcherVersion
    newest_version_binary = $currentVersion
    new_msedge_exists = Test-Path -LiteralPath (Join-Path $paths.ApplicationDirectory "new_msedge.exe")
    mitigation_manager_present = $null -ne $manager
    incompatible_version = $manager.renderer_app_container_incompatible_version
    compatible_count = $manager.renderer_app_container_compatible_count
  } | Format-List
  Write-Status "仅完成诊断。确认全部网页和内置页都空白后，再运行 -Repair。"
  exit 0
}

Write-Status "请先保存 Edge 中未提交的表单或下载任务；按 Enter 后将关闭 Edge。"
[void](Read-Host)
Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (Get-Process -Name msedge -ErrorAction SilentlyContinue) {
  throw "Edge 仍在运行，停止处理。"
}

if (-not $SkipUpdate) {
  Write-Status "尝试通过官方 winget 源覆盖安装 Edge。"
  & winget install --id Microsoft.Edge --exact --source winget --force --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) {
    throw "Edge 覆盖安装失败，exit code: $LASTEXITCODE"
  }
  $paths = Get-EdgePaths
}

$backupRoot = Copy-EdgeBackup -UserDataPath $paths.UserData
Write-Status "完整备份已校验：$backupRoot"

$testBase = Join-Path $env:TEMP ("edge-renderer-diagnostic-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$freshProfile = Join-Path $testBase "fresh"
$copiedStateProfile = Join-Path $testBase "copied-local-state"
New-Item -ItemType Directory -Path $freshProfile, $copiedStateProfile -Force | Out-Null

try {
  $fresh = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $freshProfile
  if ($fresh.RendererCount -lt 1) {
    throw "全新临时 profile 也没有 renderer，不属于本文可自动修复的故障链。"
  }

  Copy-Item -LiteralPath $paths.LocalState -Destination (Join-Path $copiedStateProfile "Local State")
  $copied = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $copiedStateProfile
  if ($copied.RendererCount -gt 0) {
    throw "只复制 Local State 未复现故障，停止处理原文件。"
  }

  Remove-MitigationManager -LocalStatePath (Join-Path $copiedStateProfile "Local State")
  $repairedCopy = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $copiedStateProfile
  if ($repairedCopy.RendererCount -lt 1) {
    throw "临时副本修复后仍没有 renderer，停止处理原文件。"
  }
} finally {
  if (Test-Path -LiteralPath $testBase) {
    Remove-Item -LiteralPath $testBase -Recurse -Force
  }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rollbackPath = "$($paths.LocalState).pre-mitigation-fix-$timestamp.bak"
$temporaryPath = "$($paths.LocalState).repair-tmp"
Copy-Item -LiteralPath $paths.LocalState -Destination $rollbackPath
Copy-Item -LiteralPath $paths.LocalState -Destination $temporaryPath
Remove-MitigationManager -LocalStatePath $temporaryPath
Move-Item -LiteralPath $temporaryPath -Destination $paths.LocalState -Force

Start-Process -FilePath $paths.Launcher -ArgumentList "edge://settings"
Start-Sleep -Seconds 7
$normalProfileRenderers = @(
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -match "--type=renderer" }
).Count

if ($normalProfileRenderers -lt 1) {
  throw "原配置启动后仍没有 renderer；回滚文件保留在：$rollbackPath"
}

Write-Status "修复完成。原配置 renderer：$normalProfileRenderers；完整备份：$backupRoot；单文件回滚：$rollbackPath"
