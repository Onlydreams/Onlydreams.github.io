---
layout: post
title: "Codex Desktop 插件页渲染异常的 GPU 启动参数修复"
date: 2026-05-17 00:00:00 +0800
categories: [AI, 工具, macOS]
tags: [codex, electron, gpu, macos, intel, plugin]
---

记录一次 Codex Desktop 插件搜索页面渲染错位的排查过程，以及在 Intel Mac 上通过强制高性能 GPU 启动规避问题的方法。

---

## 现象

Codex Desktop 的插件页面可以打开，但插件搜索区和插件卡片出现明显渲染异常：

- 插件卡片内容被横向或纵向错位。
- 文字只显示一部分，部分内容被裁切。
- 右侧预览图、骨架屏和列表区域发生重叠。
- 切换页面、重启应用、清理缓存后仍然复现。

从表现看，这不像插件列表接口失败，更像 Electron / Chromium 渲染层的问题。

## 初步排查

先确认 Codex Desktop 的版本和运行环境：

```zsh
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/Codex.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' /Applications/Codex.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Applications/Codex.app/Contents/Info.plist
```

当时环境信息如下：

```text
Codex Desktop: 26.513.31313
Bundle ID: com.openai.codex
Electron: 42.0.1
macOS: 15.7.7
Architecture: x64
Screen: 3360x2100, density 2
```

再看本地 Sentry scope 里的请求记录：

```zsh
jq -r '.scope.breadcrumbs[]
  | select((.message? // "") | test("plugin/list"))
  | [.timestamp, .category, .level, .message]
  | @tsv' "$HOME/Library/Application Support/Codex/sentry/scope_v3.json"
```

可以看到 `plugin/list` 请求正常返回，没有接口失败或权限错误。因此问题不在插件市场数据本身。

## 清理缓存无效

尝试清理 Electron / Chromium 常见缓存：

```zsh
rm -rf "$HOME/Library/Application Support/Codex/Cache" \
       "$HOME/Library/Application Support/Codex/GPUCache" \
       "$HOME/Library/Application Support/Codex/DawnGraphiteCache" \
       "$HOME/Library/Application Support/Codex/DawnWebGPUCache" \
       "$HOME/Library/Application Support/Codex/Code Cache"
```

重新打开 Codex 后，插件页仍然错位。由此可以排除普通缓存损坏。

## 最终修复

解决方案来自 [openai/codex#18774](https://github.com/openai/codex/issues/18774)。

在 Intel Mac 上，通过启动参数强制 Codex 使用高性能 GPU：

```zsh
open -na "/Applications/Codex.app" --args --force_high_performance_gpu
```

执行后，插件搜索页面恢复正常。

这个结果说明：插件页渲染异常与默认 GPU 选择路径有关。`--force_high_performance_gpu` 避开了默认 Electron / Chromium GPU compositing 路径中的问题。

## 从 Dock 启动

Dock 里的原始 `Codex.app` 不能直接附加启动参数。可以创建一个 AppleScript 启动器，再把启动器固定到 Dock。

```zsh
mkdir -p "$HOME/Applications"

osacompile -o "$HOME/Applications/Codex GPU.app" -e '
do shell script "open -na /Applications/Codex.app --args --force_high_performance_gpu"
'
```

然后在 Finder 打开 `~/Applications`，把 `Codex GPU.app` 拖到 Dock。之后从这个 Dock 图标启动 Codex，就会自动带上 `--force_high_performance_gpu` 参数。

如果希望图标和原应用一致，可以手动复制图标：

1. Finder 中选中 `/Applications/Codex.app`。
2. 按 `Cmd + I` 打开信息面板。
3. 点击左上角图标，按 `Cmd + C`。
4. 选中 `~/Applications/Codex GPU.app`。
5. 按 `Cmd + I` 打开信息面板。
6. 点击左上角图标，按 `Cmd + V`。

原 Dock 里的 Codex 图标仍然不带启动参数，建议移除，只保留 `Codex GPU.app`。

## 结论

这不是插件搜索接口问题，也不是本地缓存问题，而是 Codex Desktop 在特定 macOS Intel / GPU 路径上的前端渲染 bug。

临时规避方式是：

```zsh
open -na "/Applications/Codex.app" --args --force_high_performance_gpu
```

如果后续 Codex 官方修复了该问题，可以再回到默认启动方式。
