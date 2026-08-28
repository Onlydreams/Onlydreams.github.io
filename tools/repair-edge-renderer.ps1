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
    CurrentVersion = $currentVersionDirectory.Name
    VersionDirectories = @($versionDirectories.Name)
    UserData = $userData
    LocalState = $localState
  }
}

function Get-EdgeUpdateState {
  $clientKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
  if (-not (Test-Path -LiteralPath $clientKey)) {
    throw "找不到 Edge Update 注册状态，停止处理。"
  }

  $registration = Get-ItemProperty -LiteralPath $clientKey
  [pscustomobject]@{
    ProductVersion = [string]$registration.pv
    OldProductVersion = [string]$registration.opv
  }
}

function Test-EdgeVersionSwitchValues {
  param(
    [string]$LauncherVersion,
    [string]$CurrentVersion,
    [string]$ProductVersion,
    [string]$OldProductVersion,
    [bool]$NewMsedgeExists,
    [string[]]$VersionDirectories
  )

  $LauncherVersion -eq $CurrentVersion -and
    $ProductVersion -eq $CurrentVersion -and
    [string]::IsNullOrEmpty($OldProductVersion) -and
    -not $NewMsedgeExists -and
    $VersionDirectories.Count -eq 1 -and
    $VersionDirectories[0] -eq $CurrentVersion
}

function Test-EdgeVersionSwitch {
  param([pscustomobject]$Paths)

  $launcherVersion = (Get-Item -LiteralPath $Paths.Launcher).VersionInfo.FileVersion
  $currentVersion = (Get-Item -LiteralPath $Paths.CurrentBinary).VersionInfo.FileVersion
  $updateState = Get-EdgeUpdateState
  $newMsedgeExists = Test-Path -LiteralPath (Join-Path $Paths.ApplicationDirectory "new_msedge.exe")
  $isComplete = Test-EdgeVersionSwitchValues `
    -LauncherVersion $launcherVersion `
    -CurrentVersion $currentVersion `
    -ProductVersion $updateState.ProductVersion `
    -OldProductVersion $updateState.OldProductVersion `
    -NewMsedgeExists $newMsedgeExists `
    -VersionDirectories $Paths.VersionDirectories

  [pscustomobject]@{
    LauncherVersion = $launcherVersion
    CurrentVersion = $currentVersion
    ProductVersion = $updateState.ProductVersion
    OldProductVersion = $updateState.OldProductVersion
    NewMsedgeExists = $newMsedgeExists
    VersionDirectories = $Paths.VersionDirectories
    IsComplete = $isComplete
  }
}

function Test-EdgeEntrypointTargets {
  param(
    [string]$Launcher,
    [pscustomobject[]]$Entrypoints
  )

  $expectedLauncher = [System.IO.Path]::GetFullPath($Launcher)
  $staleEntries = @(
    foreach ($entry in $Entrypoints) {
      $matches = if ($entry.Type -eq "Shortcut") {
        [System.IO.Path]::GetFullPath($entry.Target) -eq $expectedLauncher
      } else {
        [string]$entry.Target -like "*$expectedLauncher*"
      }
      if (-not $matches) {
        $entry
      }
    }
  )

  [pscustomobject]@{
    CheckedCount = $Entrypoints.Count
    StaleEntries = $staleEntries
    IsComplete = $Entrypoints.Count -gt 0 -and $staleEntries.Count -eq 0
  }
}

function Get-EdgeEntrypointState {
  param([string]$Launcher)

  $entries = @()
  $registryPaths = @(
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge\shell\open\command",
    "Registry::HKEY_CLASSES_ROOT\MSEdgeHTM\shell\open\command",
    "Registry::HKEY_CLASSES_ROOT\MSEdgePDF\shell\open\command",
    "Registry::HKEY_CLASSES_ROOT\microsoft-edge\shell\open\command"
  )
  foreach ($registryPath in $registryPaths) {
    if (Test-Path -LiteralPath $registryPath) {
      $entries += [pscustomobject]@{
        Type = "Registry"
        Location = $registryPath
        Target = (Get-Item -LiteralPath $registryPath).GetValue("")
      }
    }
  }

  $shortcutDirectories = @(
    (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"),
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"),
    (Join-Path $env:PUBLIC "Desktop"),
    (Join-Path $env:USERPROFILE "Desktop"),
    (Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
  )
  $shell = New-Object -ComObject WScript.Shell
  foreach ($directory in $shortcutDirectories) {
    if (-not (Test-Path -LiteralPath $directory)) {
      continue
    }
    foreach ($shortcutFile in Get-ChildItem -LiteralPath $directory -Filter "*.lnk" -File -ErrorAction SilentlyContinue) {
      $shortcut = $shell.CreateShortcut($shortcutFile.FullName)
      if ($shortcut.TargetPath -match "msedge\.exe$") {
        $entries += [pscustomobject]@{
          Type = "Shortcut"
          Location = $shortcutFile.FullName
          Target = $shortcut.TargetPath
        }
      }
    }
  }

  Test-EdgeEntrypointTargets -Launcher $Launcher -Entrypoints $entries
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
  }

  foreach ($attempt in 1..10) {
    if ((Get-RendererCount -ProfilePath $ProfilePath).ProcessCount -eq 0) {
      Start-Sleep -Seconds 2
      return
    }
    Start-Sleep -Seconds 1
  }

  throw "临时 Edge profile 仍有进程占用，停止处理：$ProfilePath"
}

function Assert-TemporaryDirectoryPath {
  param([string]$Path)

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $resolvedTemp = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd("\") + "\"
  if (-not $resolvedPath.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "拒绝清理非临时目录：$resolvedPath"
  }

  $resolvedPath
}

function Remove-TemporaryDirectory {
  param([string]$Path)

  $resolvedPath = Assert-TemporaryDirectoryPath -Path $Path

  foreach ($attempt in 1..5) {
    try {
      Remove-Item -LiteralPath $resolvedPath -Recurse -Force
      return
    } catch {
      if ($attempt -eq 5) {
        throw
      }
      Start-Sleep -Seconds 1
    }
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

function Invoke-EdgeRendererRepair {
  param(
    [switch]$RepairRequested,
    [switch]$SkipUpdateRequested
  )

  $paths = Get-EdgePaths
  $launcherVersion = (Get-Item -LiteralPath $paths.Launcher).VersionInfo.FileVersion
  $currentVersion = (Get-Item -LiteralPath $paths.CurrentBinary).VersionInfo.FileVersion
  $versionSwitch = Test-EdgeVersionSwitch -Paths $paths
  $state = Get-Content -LiteralPath $paths.LocalState -Raw | ConvertFrom-Json
  $manager = $state.edge.mitigation_manager

  if (-not $RepairRequested) {
    $entrypoints = Get-EdgeEntrypointState -Launcher $paths.Launcher
  [pscustomobject]@{
    launcher_version = $launcherVersion
    newest_version_binary = $currentVersion
    version_directories = $versionSwitch.VersionDirectories -join ", "
    registered_version = $versionSwitch.ProductVersion
    old_registered_version = $versionSwitch.OldProductVersion
    new_msedge_exists = $versionSwitch.NewMsedgeExists
    version_switch_complete = $versionSwitch.IsComplete
    entrypoints_checked = $entrypoints.CheckedCount
    entrypoints_complete = $entrypoints.IsComplete
    mitigation_manager_present = $null -ne $manager
    incompatible_version = $manager.renderer_app_container_incompatible_version
    compatible_count = $manager.renderer_app_container_compatible_count
  } | Format-List
  Write-Status "仅完成诊断。确认全部网页和内置页都空白后，再运行 -Repair。"
    return
  }

Write-Status "请先保存 Edge 中未提交的表单或下载任务；按 Enter 后将关闭 Edge。"
[void](Read-Host)
Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (Get-Process -Name msedge -ErrorAction SilentlyContinue) {
  throw "Edge 仍在运行，停止处理。"
}

$backupRoot = Copy-EdgeBackup -UserDataPath $paths.UserData
Write-Status "更新前完整备份已校验：$backupRoot"

if (-not $SkipUpdateRequested) {
  Write-Status "尝试通过官方 winget 源覆盖安装 Edge。"
  & winget install --id Microsoft.Edge --exact --source winget --force --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) {
    throw "Edge 覆盖安装失败，exit code: $LASTEXITCODE"
  }
  $paths = Get-EdgePaths
}

$versionSwitch = Test-EdgeVersionSwitch -Paths $paths
if (-not $versionSwitch.IsComplete) {
  throw "Edge 版本切换未完成：launcher=$($versionSwitch.LauncherVersion)，pv=$($versionSwitch.ProductVersion)，opv=$($versionSwitch.OldProductVersion)，new_msedge=$($versionSwitch.NewMsedgeExists)，版本目录=$($versionSwitch.VersionDirectories -join ',')。停止修改 Local State。"
}
Write-Status "版本入口已收敛：$($versionSwitch.CurrentVersion)"

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
    Remove-TemporaryDirectory -Path $testBase
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
$firstColdStartRenderers = @(
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -match "--type=renderer" }
).Count

if ($firstColdStartRenderers -lt 1) {
  throw "原配置启动后仍没有 renderer；回滚文件保留在：$rollbackPath"
}

Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
if (Get-Process -Name msedge -ErrorAction SilentlyContinue) {
  throw "首次冷启动后 Edge 未完全退出，停止最终验收。"
}

Start-Process -FilePath $paths.Launcher -ArgumentList @("edge://settings", "https://example.com/")
Start-Sleep -Seconds 7
$secondColdStartRenderers = @(
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -match "--type=renderer" }
).Count
$finalVersionSwitch = Test-EdgeVersionSwitch -Paths (Get-EdgePaths)
$finalEntrypoints = Get-EdgeEntrypointState -Launcher $paths.Launcher

if ($secondColdStartRenderers -lt 1 -or -not $finalVersionSwitch.IsComplete -or -not $finalEntrypoints.IsComplete) {
  throw "最终自动验收失败；第二次冷启动 renderer=$secondColdStartRenderers，版本切换完成=$($finalVersionSwitch.IsComplete)，入口检查=$($finalEntrypoints.CheckedCount)，旧入口=$($finalEntrypoints.StaleEntries.Count)。回滚文件保留在：$rollbackPath"
}

Write-Status "自动检查通过。请确认 Edge 中的 edge://settings 与 https://example.com/ 均已显示实际内容。"
$pageConfirmation = Read-Host "两页均正常时输入 YES"
if ($pageConfirmation -cne "YES") {
  throw "未完成人工页面验收，不声明完整修复。回滚文件保留在：$rollbackPath"
}

Write-Status "完整修复验收完成。两次冷启动 renderer：$firstColdStartRenderers / $secondColdStartRenderers；版本入口：$($finalVersionSwitch.CurrentVersion)；已检查入口：$($finalEntrypoints.CheckedCount)；完整备份：$backupRoot；单文件回滚：$rollbackPath"
}

if ($MyInvocation.InvocationName -ne ".") {
  Invoke-EdgeRendererRepair -RepairRequested:$Repair -SkipUpdateRequested:$SkipUpdate
}
