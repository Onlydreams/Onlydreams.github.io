---
layout: post
lang: en
translation_key: microsoft-edge-blank-pages-renderer-state-repair
title: "Microsoft Edge Goes Blank After Edge Updates: Recurrent Renderer-State Failures and a Data-Preserving Repair"
date: 2026-08-11 10:55:00 +0800
updated: 2026-08-19
author: Onlydreams
categories: [Developer Tools, Browsers]
tags: [edge, windows, renderer, extension, troubleshooting]
status:
  label: 当前可用
  verified: 2026-08-19
  environment: Windows x64 build 26200.8973 / Microsoft Edge Stable 149.0.4022.98 → 150.0.4078.83, 150.0.4078.83 → 151.0.4129.72, 151.0.4129.72 → 151.0.4129.93 / Edge Update 1.3.225.7
  risk: The same failure chain recurred three times on one device (two major-version updates and one same-major patch update), but that does not mean every device is affected. edge.mitigation_manager is undocumented internal state; modify it only after a verified backup and an isolated copy prove the same causal link.
---

Microsoft Edge reached the same failure state three times — after the 149→150 and 150→151 Stable major updates and again during the same-major patch update 151.0.4129.72 → 151.0.4129.93: every website, Settings page, and extension page was blank while the browser process remained alive. In every incident, the new binary had been downloaded and registered without replacing the active binary, and stale renderer AppContainer compatibility state then prevented every renderer process from surviving.

---

## The short version

This was not an individual extension failure and it was not fixed by resetting the entire profile. Two layers had to be repaired independently:

1. Complete the pending Edge binary switch with an official package reinstall.
2. After a full backup and copy-based isolation, remove only `edge.mitigation_manager` from the top-level `Local State` file and let the current Edge version rebuild it.

The first incident occurred during the 149→150 update on July 25, 2026. The same chain returned during 150→151 on August 11 and again during the same-major patch update on August 19.

| Evidence | 149→150 | 150→151 |
|---|---|---|
| Active `msedge.exe` | `149.0.4022.98` | `150.0.4078.83` |
| Registered/pending version | `150.0.4078.83` | `151.0.4129.72` |
| `new_msedge.exe` | Present | Present since August 6 |
| Renderer processes with the original profile | 0 | 0 in three consecutive samples |
| `renderer_app_container_incompatible_version` | `149.0.4022.98` | `150.0.4078.83` |
| `renderer_app_container_compatible_count` | 100 | 100 |

During the second incident, six Edge processes remained: the browser, GPU, network, and utility processes were alive, but the renderer count was zero. The current Breadcrumbs file contained 30 `RenderProcessGone` and 14 `ERR_ABORTED` entries.

## Quick fix: one command, and it stops on any mismatch

For this article's exact failure fingerprint, the repository provides an auditable [repair-edge-renderer.ps1]({{ '/tools/repair-edge-renderer.ps1' | relative_url }}). It bundles backup, isolated comparison, rollback, field-level repair, and cold-start re-verification into one entry point; it will not touch `Local State` just because a website fails to open.

Start with read-only diagnostics:

```powershell
$script = Join-Path $env:TEMP "repair-edge-renderer.ps1"
Invoke-WebRequest "https://www.dayjia.com/tools/repair-edge-renderer.ps1" -OutFile $script
powershell -NoProfile -ExecutionPolicy Bypass -File $script
```

Once you have confirmed that both normal pages and `edge://settings` are blank, run the repair. It will ask you to save your forms and then closes Edge; `ExecutionPolicy Bypass` applies only to this child process and does not change the system execution policy.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $script -Repair
```

The script attempts an official winget reinstall, backs up and verifies the complete `User Data`, verifies that a fresh profile produces renderers, verifies that copying only the original `Local State` drops renderers to zero, verifies that removing the target object from the copy restores renderers, and only then modifies the original file while leaving a single-file rollback copy. Any failed step stops the script; do not skip the conditions and edit the file manually.

If you have already completed the official reinstall manually and only want to skip the update step inside the script, pass `-SkipUpdate`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $script -Repair -SkipUpdate
```

The script only fits the global renderer-crash fingerprint in this article; it is not a universal Edge blank-page fixer. It never deletes the whole `User Data`, `Default`, cookies, passwords, history, or extensions; the complete backup stays in `%LOCALAPPDATA%\Edge-Recovery` and the temporary isolation copies are removed automatically after verification.

### Full script: the download and the article stay in sync

The full source below is embedded from the repository's single canonical copy (`tools/repair-edge-renderer.ps1`): after changing the script, run `ruby bin/embed_article_scripts.rb` to re-embed it, and `test/content_health_test.rb` verifies byte-for-byte that the article matches the source (GitHub Pages' safe build mode does not run custom Jekyll plugins, so no template tags are used). The web page, the download link, and the file in the repository are therefore always the same content. If you prefer not to run the downloaded file, you can save the full text below as a `.ps1` file. The script's status messages are in Chinese; the behavior is described above.

<details class="source-disclosure">
<summary class="source-disclosure__summary">
<span class="source-disclosure__title"><span class="source-disclosure__chevron" aria-hidden="true"></span><span class="source-disclosure__closed-label">Expand</span><span class="source-disclosure__open-label">Collapse</span> the full <code>repair-edge-renderer.ps1</code> source</span>
<span class="source-disclosure__meta">PowerShell · Synced with download</span>
</summary>

<div class="source-code-block" data-copy-mode="raw" data-copy-label="Copy full source" data-copying-label="Copying" data-copied-label="Copied" data-copy-error-label="Copy failed">
<pre><code class="language-powershell">[CmdletBinding()]
param(
  [switch]$Repair,
  [switch]$SkipUpdate
)

$ErrorActionPreference = &quot;Stop&quot;

function Write-Status {
  param([string]$Message)
  Write-Host &quot;[Edge renderer repair] $Message&quot;
}

function Get-EdgePaths {
  $applicationDirectory = Join-Path ${env:ProgramFiles(x86)} &quot;Microsoft\Edge\Application&quot;
  $launcher = Join-Path $applicationDirectory &quot;msedge.exe&quot;
  $userData = Join-Path $env:LOCALAPPDATA &quot;Microsoft\Edge\User Data&quot;
  $localState = Join-Path $userData &quot;Local State&quot;

  if (-not (Test-Path -LiteralPath $launcher)) {
    throw &quot;找不到 Edge 启动文件：$launcher&quot;
  }
  if (-not (Test-Path -LiteralPath $localState)) {
    throw &quot;找不到 Edge Local State，停止处理。&quot;
  }

  $versionDirectories = @(
    Get-ChildItem -LiteralPath $applicationDirectory -Directory |
      Where-Object { $_.Name -match &quot;^\d+\.\d+\.\d+\.\d+$&quot; } |
      Sort-Object { [version]$_.Name } -Descending
  )
  $currentVersionDirectory = $versionDirectories | Select-Object -First 1
  if (-not $currentVersionDirectory) {
    throw &quot;找不到 Edge 版本目录，停止处理。&quot;
  }

  $currentBinary = Join-Path $currentVersionDirectory.FullName &quot;msedge.exe&quot;
  if (-not (Test-Path -LiteralPath $currentBinary)) {
    throw &quot;找不到当前版本 Edge 二进制，停止处理。&quot;
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
    Get-CimInstance Win32_Process -Filter &quot;Name = &#39;msedge.exe&#39;&quot; |
      Where-Object { $_.CommandLine -like &quot;*$ProfilePath*&quot; }
  )
  [pscustomobject]@{
    ProcessCount = $processes.Count
    RendererCount = @($processes | Where-Object { $_.CommandLine -match &quot;--type=renderer&quot; }).Count
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
    &quot;--user-data-dir=$ProfilePath&quot;,
    &quot;--no-first-run&quot;,
    &quot;--disable-extensions&quot;,
    &quot;edge://settings&quot;
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

  $backupBase = Join-Path $env:LOCALAPPDATA &quot;Edge-Recovery&quot;
  $backupRoot = Join-Path $backupBase (&quot;Edge-User-Data-backup-&quot; + (Get-Date -Format &quot;yyyyMMdd-HHmmss&quot;))
  New-Item -ItemType Directory -Path $backupBase -Force | Out-Null

  &amp; robocopy $UserDataPath $backupRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP
  if ($LASTEXITCODE -ge 8) {
    throw &quot;Edge 用户数据备份失败，Robocopy exit code: $LASTEXITCODE&quot;
  }

  $criticalFiles = @(&quot;Local State&quot;, &quot;Default\Bookmarks&quot;, &quot;Default\History&quot;, &quot;Default\Login Data&quot;, &quot;Default\Network\Cookies&quot;, &quot;Default\Preferences&quot;)
  foreach ($relativePath in $criticalFiles) {
    $source = Join-Path $UserDataPath $relativePath
    $backup = Join-Path $backupRoot $relativePath
    if ((Test-Path -LiteralPath $source) -and ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash)) {
      throw &quot;备份校验失败：$relativePath&quot;
    }
  }

  $backupRoot
}

function Remove-MitigationManager {
  param([string]$LocalStatePath)

  $state = Get-Content -LiteralPath $LocalStatePath -Raw | ConvertFrom-Json
  if (-not $state.edge -or -not ($state.edge.PSObject.Properties.Name -contains &quot;mitigation_manager&quot;)) {
    throw &quot;edge.mitigation_manager 不存在，停止处理。&quot;
  }
  $state.edge.PSObject.Properties.Remove(&quot;mitigation_manager&quot;)
  $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($LocalStatePath, ($state | ConvertTo-Json -Depth 100 -Compress), $utf8WithoutBom)

  $validated = Get-Content -LiteralPath $LocalStatePath -Raw | ConvertFrom-Json
  if ($validated.edge.PSObject.Properties.Name -contains &quot;mitigation_manager&quot;) {
    throw &quot;验证失败：临时文件中的目标对象仍然存在。&quot;
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
    new_msedge_exists = Test-Path -LiteralPath (Join-Path $paths.ApplicationDirectory &quot;new_msedge.exe&quot;)
    mitigation_manager_present = $null -ne $manager
    incompatible_version = $manager.renderer_app_container_incompatible_version
    compatible_count = $manager.renderer_app_container_compatible_count
  } | Format-List
  Write-Status &quot;仅完成诊断。确认全部网页和内置页都空白后，再运行 -Repair。&quot;
  exit 0
}

Write-Status &quot;请先保存 Edge 中未提交的表单或下载任务；按 Enter 后将关闭 Edge。&quot;
[void](Read-Host)
Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (Get-Process -Name msedge -ErrorAction SilentlyContinue) {
  throw &quot;Edge 仍在运行，停止处理。&quot;
}

if (-not $SkipUpdate) {
  Write-Status &quot;尝试通过官方 winget 源覆盖安装 Edge。&quot;
  &amp; winget install --id Microsoft.Edge --exact --source winget --force --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) {
    throw &quot;Edge 覆盖安装失败，exit code: $LASTEXITCODE&quot;
  }
  $paths = Get-EdgePaths
}

$backupRoot = Copy-EdgeBackup -UserDataPath $paths.UserData
Write-Status &quot;完整备份已校验：$backupRoot&quot;

$testBase = Join-Path $env:TEMP (&quot;edge-renderer-diagnostic-&quot; + (Get-Date -Format &quot;yyyyMMdd-HHmmss&quot;))
$freshProfile = Join-Path $testBase &quot;fresh&quot;
$copiedStateProfile = Join-Path $testBase &quot;copied-local-state&quot;
New-Item -ItemType Directory -Path $freshProfile, $copiedStateProfile -Force | Out-Null

try {
  $fresh = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $freshProfile
  if ($fresh.RendererCount -lt 1) {
    throw &quot;全新临时 profile 也没有 renderer，不属于本文可自动修复的故障链。&quot;
  }

  Copy-Item -LiteralPath $paths.LocalState -Destination (Join-Path $copiedStateProfile &quot;Local State&quot;)
  $copied = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $copiedStateProfile
  if ($copied.RendererCount -gt 0) {
    throw &quot;只复制 Local State 未复现故障，停止处理原文件。&quot;
  }

  Remove-MitigationManager -LocalStatePath (Join-Path $copiedStateProfile &quot;Local State&quot;)
  $repairedCopy = Test-ProfileRenderer -EdgeBinary $paths.CurrentBinary -ProfilePath $copiedStateProfile
  if ($repairedCopy.RendererCount -lt 1) {
    throw &quot;临时副本修复后仍没有 renderer，停止处理原文件。&quot;
  }
} finally {
  if (Test-Path -LiteralPath $testBase) {
    Remove-Item -LiteralPath $testBase -Recurse -Force
  }
}

$timestamp = Get-Date -Format &quot;yyyyMMdd-HHmmss&quot;
$rollbackPath = &quot;$($paths.LocalState).pre-mitigation-fix-$timestamp.bak&quot;
$temporaryPath = &quot;$($paths.LocalState).repair-tmp&quot;
Copy-Item -LiteralPath $paths.LocalState -Destination $rollbackPath
Copy-Item -LiteralPath $paths.LocalState -Destination $temporaryPath
Remove-MitigationManager -LocalStatePath $temporaryPath
Move-Item -LiteralPath $temporaryPath -Destination $paths.LocalState -Force

Start-Process -FilePath $paths.Launcher -ArgumentList &quot;edge://settings&quot;
Start-Sleep -Seconds 7
$normalProfileRenderers = @(
  Get-CimInstance Win32_Process -Filter &quot;Name = &#39;msedge.exe&#39;&quot; |
    Where-Object { $_.CommandLine -match &quot;--type=renderer&quot; }
).Count

if ($normalProfileRenderers -lt 1) {
  throw &quot;原配置启动后仍没有 renderer；回滚文件保留在：$rollbackPath&quot;
}

Write-Status &quot;修复完成。原配置 renderer：$normalProfileRenderers；完整备份：$backupRoot；单文件回滚：$rollbackPath&quot;
</code></pre>
</div>
</details>

## 2026-08-19: the same-major patch update recurred

The first two samples happened to be `149→150` and `150→151`, which is no reason to generalize that "only major versions fail". On 2026-08-19 the failure returned during `151.0.4129.72 → 151.0.4129.93`: the major version stayed at 151, but the update directory already contained `.93` while the root launcher still reported `.72` and `new_msedge.exe` was still present.

Opening `edge://settings` with the original profile left 6 Edge processes with 0 renderers; `renderer_app_container_incompatible_version` in `Local State` was still `.72` with a compatibility count of 100. Isolating with the `.93` binary produced:

| Temporary profile | Renderer count |
|---|---:|
| Fresh profile | 3 |
| Fresh profile with only the original `Local State` | 0 |
| Same copy without `edge.mitigation_manager` | 3 |

Applying the same minimal change to the original file, the normal entry point first produced 6 renderers in the built-in settings page; after one cold start, a normal page produced 10 renderers, and `edge.mitigation_manager` was rebuilt with the compatibility count reset to zero. This proves the state object was necessary for this zero-renderer recurrence; it does not prove that Microsoft has confirmed a universal root cause or that future updates will use the same mechanism.

## Failure signature

Use this article only when several of these signals appear together:

- Normal websites, `edge://settings`, and `edge://extensions` are all blank or crash.
- Several extensions report crashes at the same time.
- The browser, network, and GPU processes remain alive, but no process has `--type=renderer`.
- Edge Breadcrumbs repeatedly record `RenderProcessGone` and `ERR_ABORTED` after navigation.
- The active `msedge.exe` version is older than the registered version.
- A target-version `new_msedge.exe` remains in the application directory.
- `edge.mitigation_manager` identifies the active old version as renderer-AppContainer incompatible and the compatibility count has reached 100.
- A fresh temporary profile creates renderers, but copying only the original `Local State` into another fresh profile makes the renderer count return to zero.

If only one website fails, a temporary profile also fails, renderer processes exist normally, or the binary versions already matched before the failure, this is not the chain verified here. Investigate networking, GPU state, system policy, security software, or a specific extension instead.

As of August 11, 2026, the Microsoft Edge known-issues page did not list this exact combination. The internal state fields are not a public contract. The point of this write-up is the isolation method, not a universal instruction to delete browser state.

## Why resetting the profile is the wrong first move

Several extensions failing together suggests a shared renderer failure before it suggests several independent extension failures. Disabling extensions did not change the zero-renderer result.

Microsoft's troubleshooting guidance recommends ending background Edge processes, checking graphics acceleration, comparing against a temporary profile, and repairing the installation when necessary. A healthy temporary profile proves only that the failure is associated with the original user-state scope. It does not prove that the entire `Default` directory is permanently corrupted.

An earlier full-profile reset temporarily recovered this device because it generated a new `Local State`, but it did not complete the stuck binary update. The same renderer state returned later, and local data that had not been restored was lost.

Do not begin by doing any of the following:

- deleting or renaming the entire `User Data` directory;
- deleting or recreating `Default`;
- uninstalling extensions in bulk;
- clearing cookies, passwords, or history;
- editing `Local State` while Edge is running.

## Build a renderer-based feedback loop

The pass/fail signal throughout both investigations was simple: **can renderer processes survive and finish page loads?**

| Probe | Result | What it establishes |
|---|---|---|
| Original profile | 0 renderers | Reproduces the failure |
| Original profile with extensions disabled | 0 renderers | A single extension is not the direct cause |
| Same Edge binary with a fresh profile | Multiple renderers | The program can create renderers in the same OS environment |
| Fresh profile with only the original `Local State` | 0 renderers | Narrows the failure to one top-level state file |
| Same copied file without `edge.mitigation_manager` | Renderers return | Narrows the causal change to one object |

### Compare the active and registered versions

```powershell
$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

(Get-Item -LiteralPath $edgeExe).VersionInfo.FileVersion
winget list --id Microsoft.Edge --exact
```

The first failure showed an active 149 binary with 150 registered. The second showed an active 150 binary while winget and `new_msedge.exe` were already at 151. Both 150 and 151 application directories remained until the reinstall completed the switch.

Microsoft documents “the installation finishes, but the version doesn't change” as an Edge Update failure symptom. System-level update logs are normally stored at:

```text
%ALLUSERSPROFILE%\Microsoft\EdgeUpdate\Log\MicrosoftEdgeUpdate.log
```

A per-user installation can also use:

```text
%LOCALAPPDATA%\Temp\MicrosoftEdgeUpdate.log
```

### Count renderer processes

```powershell
$edgeProcesses = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'"

$rendererCount = @(
  $edgeProcesses |
    Where-Object { $_.CommandLine -match '--type=renderer' }
).Count

"Renderer count: $rendererCount"
```

The number of `msedge.exe` processes alone is not useful. A live browser process does not mean the webpage renderer is healthy.

Process command lines may contain usernames, profile paths, startup URLs, or extension IDs. Do not paste raw command-line output into a public issue. Share only process types and counts after removing paths, URLs, profile names, and identifiers.

### Compare with a temporary profile

Save any unsent form content, close Edge completely, and confirm that no `msedge.exe` process remains. Then launch an isolated profile:

```powershell
$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$testProfile = Join-Path $env:TEMP "edge-test-profile"

& $edgeExe `
  --user-data-dir="$testProfile" `
  --no-first-run `
  --disable-extensions `
  "https://www.bing.com/"
```

If this profile also has no renderer, continue investigating the program installation, GPU, policy, or security software. Do not modify the original user data.

If the temporary profile is healthy, copy individual state files into separate disposable profiles and repeat the renderer check. Do not jump directly from “fresh profile works” to “recreate everything.”

### Inspect only the relevant compatibility state

With Edge closed, read the top-level `Local State` file:

```powershell
$localStatePath = Join-Path $env:LOCALAPPDATA `
  "Microsoft\Edge\User Data\Local State"

$localState = Get-Content -LiteralPath $localStatePath -Raw |
  ConvertFrom-Json

$localState.edge.mitigation_manager |
  ConvertTo-Json -Depth 10
```

The first incident identified 149 as the incompatible renderer-AppContainer version; the second identified 150. Both compatibility counts were 100. Those values were consistent with the active binary and the zero-renderer symptom, but reading the values was not sufficient evidence to edit the file.

The causal evidence came from disposable copies: the original `Local State` reproduced the failure in a fresh profile, and removing only `edge.mitigation_manager` from that copy restored renderers.

Do not upload the full `Local State`, `User Data`, cookie or login databases, raw command lines, or unreviewed update logs. They can reveal accounts, sites, profile names, local paths, and device identifiers.

## Repair layer one: complete the binary switch

Create and verify a complete backup before changing either layer. The `User Data` directory contains cookies, password databases, history, and extension state. Do not place this backup on the Desktop, OneDrive, another synchronized folder, or a public issue attachment.

This example uses `%LOCALAPPDATA%\Edge-Recovery`, which must resolve outside the source directory:

```powershell
$edgeUserData = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data"
$backupBase = Join-Path $env:LOCALAPPDATA "Edge-Recovery"
$backupRoot = Join-Path $backupBase `
  ("Edge-User-Data-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Path $backupBase -Force |
  Out-Null

robocopy $edgeUserData $backupRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ

if ($LASTEXITCODE -ge 8) {
  throw "Edge user-data backup failed. Robocopy exit code: $LASTEXITCODE"
}
```

Compare at least Bookmarks, History, Login Data, Cookies, `Preferences`, and `Local State` by file count, size, or SHA-256. Continue only after the backup is readable and the critical files match.

Save open work and close Edge. Also close WebView2 applications when doing so does not disrupt required connectivity. Prefer the normal Windows repair path first:

```text
Settings → Apps → Installed apps → Microsoft Edge → Modify → Repair
```

On this device, the graphical repair path reported an installer-version mismatch, while a normal `winget upgrade` refused because the registered version was already current. The verified fallback was an official-source reinstall of the registered version:

```powershell
winget install --id Microsoft.Edge --exact --source winget --force
```

This is a recovery path for the verified mismatch, not a replacement for normal Edge updates. Afterward, confirm that:

- the active `msedge.exe` matches the registered version;
- `new_msedge.exe` has disappeared;
- only the current application version directory remains;
- the update log no longer repeats the old/new mismatch.

During both incidents, this step completed the binary switch but the original profile still produced zero renderers. The update mismatch was one layer, not the entire failure.

## Repair layer two: remove only the proven rebuildable object

Proceed only when all three conditions are true:

1. A complete `User Data` backup has been created and verified.
2. The active and registered Edge versions match, but the original profile still has no renderer.
3. An isolated copy proves that the original `Local State` reproduces the failure and removing only `edge.mitigation_manager` restores renderers.

The following PowerShell creates a single-file rollback copy, removes only the target object, writes through a temporary file, and parses the result again before replacing the original:

```powershell
$ErrorActionPreference = "Stop"

if (Get-Process msedge -ErrorAction SilentlyContinue) {
  throw "Edge is still running. Local State was not modified."
}

$localStatePath = Join-Path $env:LOCALAPPDATA `
  "Microsoft\Edge\User Data\Local State"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rollbackPath = "$localStatePath.pre-mitigation-fix-$timestamp.bak"
$temporaryPath = "$localStatePath.repair-tmp"

$localState = Get-Content -LiteralPath $localStatePath -Raw |
  ConvertFrom-Json

if (
  -not $localState.edge -or
  -not (
    $localState.edge.PSObject.Properties.Name -contains "mitigation_manager"
  )
) {
  throw "edge.mitigation_manager is absent. No change was made."
}

Copy-Item -LiteralPath $localStatePath `
  -Destination $rollbackPath

$localState.edge.PSObject.Properties.Remove("mitigation_manager")

$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
$updatedText = $localState |
  ConvertTo-Json -Depth 100 -Compress

[System.IO.File]::WriteAllText(
  $temporaryPath,
  $updatedText,
  $utf8WithoutBom
)

$validated = Get-Content -LiteralPath $temporaryPath -Raw |
  ConvertFrom-Json

if (
  $validated.edge.PSObject.Properties.Name -contains "mitigation_manager"
) {
  Remove-Item -LiteralPath $temporaryPath -Force
  throw "Validation failed. The original file was not modified."
}

Move-Item -LiteralPath $temporaryPath `
  -Destination $localStatePath `
  -Force

"Rollback file: $rollbackPath"
```

This script reserializes the whole JSON document, so it is not risk-free. The complete directory backup and single-file rollback copy are both required. Do not run it if the field is absent, the disposable copy cannot reproduce the failure, or the Edge versions still differ.

To roll back, close Edge and restore the generated `.bak` file:

```powershell
Copy-Item -LiteralPath "<rollback .bak path>" `
  -Destination (Join-Path $env:LOCALAPPDATA `
    "Microsoft\Edge\User Data\Local State") `
  -Force
```

## Verification after the second repair

The original `User Data\Default` profile was preserved. After the field-level repair:

- the original profile produced renderer processes again;
- after opening a normal website and `edge://settings`, 6 renderers were alive;
- Breadcrumbs added 3 `FinishNav` and 3 `PageLoad` events;
- no new `RenderProcessGone` or `ERR_ABORTED` event appeared;
- Edge 151 rebuilt `edge.mitigation_manager` with the incompatible version updated to 151 and the compatibility count reset to zero;
- bookmarks, history, cookies, passwords, and extensions were not reset.

The acceptance test is not merely “a window opens.” Count renderers again, load both a normal website and an internal `edge://` page, and compare the same Breadcrumbs signals before and after.

Keep the full backup and single-file rollback copy for several days. Confirm cold starts, a Windows restart, and later automatic updates before deciding to remove them manually.

## What the evidence proves—and what it does not

The three investigations establish that:

- simultaneous extension failures followed the loss of all renderers;
- the 149→150, 150→151, and 151.0.4129.72→151.0.4129.93 updates all left the active binary behind the registered version;
- the original `Local State` reproduced the zero-renderer state in isolation;
- removing only `edge.mitigation_manager` from the same copied state restored renderers;
- applying the same minimum change to the original profile restored pages and extensions;
- this two-layer chain recurred three times on the same device — two consecutive major updates and one same-major patch update.

They do not establish that:

- Edge 149, Edge 150, or Edge Update has a Microsoft-confirmed universal renderer defect;
- every device or every major update will reproduce the failure;
- every blank Edge page should be repaired by deleting `edge.mitigation_manager`;
- the undocumented object will keep the same structure or behavior in future versions;
- an extension can always be ruled out from its crash notification alone.

On August 11, 2026, I submitted a redacted report through Edge's built-in Send feedback tool. Submission does not mean Microsoft has accepted the case, confirmed the cause, or scheduled a fix.

## References

- [Microsoft Learn: Microsoft Edge stops responding, shows a blank window, or fails to start](https://learn.microsoft.com/en-us/troubleshoot/microsoft-edge/performance/edge-crashes-fails-to-launch)
- [Microsoft Learn: Edge update, installation, and rollback failures](https://learn.microsoft.com/en-us/troubleshoot/microsoft-edge/manageability/update-install-rollback-failures)
- [Microsoft Learn: Microsoft Edge known issues](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-known-issues)
- [Microsoft Q&A: similar report involving every tab, Settings page, and extension](https://learn.microsoft.com/en-us/answers/questions/2398262/microsoft-edge-every-tab-crashes-instantly-includi)
