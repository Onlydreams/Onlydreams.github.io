---
layout: post
lang: en
translation_key: microsoft-edge-blank-pages-renderer-state-repair
title: "Microsoft Edge Goes Blank After Major Updates: Two Recurrent Renderer-State Failures and a Data-Preserving Repair"
date: 2026-08-11 10:55:00 +0800
author: Onlydreams
categories: [Developer Tools, Browsers]
tags: [edge, windows, renderer, extension, troubleshooting]
status:
  label: 当前可用
  verified: 2026-08-11
  environment: Windows x64 build 26200.8973 / Microsoft Edge Stable 149.0.4022.98 → 150.0.4078.83 and 150.0.4078.83 → 151.0.4129.72 / Edge Update 1.3.225.7
  risk: The same failure chain recurred across two consecutive major updates on one device, but that does not mean every device is affected. edge.mitigation_manager is undocumented internal state; modify it only after a verified backup and an isolated copy prove the same causal link.
---

Microsoft Edge twice reached the same failure state after consecutive Stable major-version updates: every website, Settings page, and extension page was blank while the browser process remained alive. In both incidents, the new binary had been downloaded and registered without replacing the active binary, and stale renderer AppContainer compatibility state then prevented every renderer process from surviving.

---

## The short version

This was not an individual extension failure and it was not fixed by resetting the entire profile. Two layers had to be repaired independently:

1. Complete the pending Edge binary switch with an official package reinstall.
2. After a full backup and copy-based isolation, remove only `edge.mitigation_manager` from the top-level `Local State` file and let the current Edge version rebuild it.

The first incident occurred during the 149→150 update on July 25, 2026. The same chain returned during 150→151 on August 11.

| Evidence | 149→150 | 150→151 |
|---|---|---|
| Active `msedge.exe` | `149.0.4022.98` | `150.0.4078.83` |
| Registered/pending version | `150.0.4078.83` | `151.0.4129.72` |
| `new_msedge.exe` | Present | Present since August 6 |
| Renderer processes with the original profile | 0 | 0 in three consecutive samples |
| `renderer_app_container_incompatible_version` | `149.0.4022.98` | `150.0.4078.83` |
| `renderer_app_container_compatible_count` | 100 | 100 |

During the second incident, six Edge processes remained: the browser, GPU, network, and utility processes were alive, but the renderer count was zero. The current Breadcrumbs file contained 30 `RenderProcessGone` and 14 `ERR_ABORTED` entries.

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

The two investigations establish that:

- simultaneous extension failures followed the loss of all renderers;
- the 149→150 and 150→151 updates both left the active binary behind the registered version;
- the original `Local State` reproduced the zero-renderer state in isolation;
- removing only `edge.mitigation_manager` from the same copied state restored renderers;
- applying the same minimum change to the original profile restored pages and extensions;
- this two-layer chain recurred across two consecutive major updates on the same device.

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
