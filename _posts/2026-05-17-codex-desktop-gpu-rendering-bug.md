---
layout: post
title: "Codex Desktop 插件页错位/渲染异常：Intel Mac GPU 启动参数修复"
date: 2026-05-17 00:00:00 +0800
updated: 2026-07-13
categories: [AI, 开发工具]
tags: [codex, electron, gpu, macos, intel, plugin]
series: [ai-agent, macos-tooling]
series_order:
  ai-agent: 3
  macos-tooling: 3
status:
  label: 待复核
  verified: 2026-07-13
  environment: Codex Desktop / Intel Mac / Electron GPU
  risk: 启动参数可能随客户端版本变化，仅适合作为同类渲染问题的排查参考。
---

记录一次 Codex Desktop 插件搜索页面渲染错位的排查过程，以及当时在 Intel Mac 上通过强制高性能 GPU 启动规避问题的方法。相关公开 issue 截至 2026-07-13 仍未关闭，但本文没有在当前版本和同类 Intel Mac 上重新复现，因此继续标记为“待复核”。

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

[openai/codex#18774](https://github.com/openai/codex/issues/18774) 记录了 Intel Mac 上侧边栏、Plugins 页面和命令浮层发生裁切或错位的同类症状。该 issue 截至 2026-07-13 仍为 open，可用于跟踪官方处理状态；issue 正文并没有把下面的启动参数列为官方修复。

在本文当时的 Intel Mac 环境中，通过启动参数强制 Codex 使用高性能 GPU 后恢复正常：

```zsh
open -na "/Applications/Codex.app" --args --force_high_performance_gpu
```

执行后，插件搜索页面在当时版本恢复正常。这是特定环境的历史实测 workaround，不是官方承诺，也不能证明所有 Intel Mac 或当前 Codex App 都应使用它。

这个前后对比说明启动参数与现象相关，但不足以确认根因。更谨慎的判断是：`--force_high_performance_gpu` 改变了 Electron / Chromium 的 GPU 选择或合成路径，并在当时环境中绕开了问题。

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

当时记录中，插件列表请求正常返回，清理常见缓存也未改变现象；启动参数曾绕过问题，但实际根因仍未确认。

临时规避方式是：

```zsh
open -na "/Applications/Codex.app" --args --force_high_performance_gpu
```

如果默认启动已经正常，应优先使用原始 Codex 图标，不要继续保留额外参数。只有能稳定复现同类错位、且默认的缩放/重启排查无效时，再临时比较该参数前后的差异。

## 参考

- [openai/codex#18774：macOS Intel UI 渲染异常](https://github.com/openai/codex/issues/18774)
