---
layout: post
title: "Claude Desktop 接入 DeepSeek：第三方模型失效后的 UpstreamKit 与 cc-switch 方案"
date: 2026-04-30 17:00:00 +0800
updated: 2026-07-13
categories: [AI, 开发工具]
tags: [claude, deepseek, api, third-party-inference, upstreamkit, cc-switch]
series: [macos-tooling]
series_order:
  macos-tooling: 2
status:
  label: 待复核
  verified: 2026-07-13
  environment: macOS / Claude Desktop / UpstreamKit / cc-switch
  risk: 项目当前仍提供代理与模型映射能力，但本文未使用真实第三方 API Key 完成端到端复测；涉及 API 配置时不要公开真实密钥。
---

这篇文章最初记录 Claude Desktop 直接配置 DeepSeek 的方式。该直连方案已经失效；2026-07-13 核验时，可行方向是使用本地兼容代理完成协议转换和模型映射，但本文没有使用真实第三方 API Key 做端到端调用，因此继续标记为“待复核”。

---

## 已失效的历史方案

旧方案直接把 Claude Desktop 的 Third-Party Inference Gateway 指向第三方兼容接口，再手动填入一个映射模型 ID。随着客户端对白名单、模型目录和协议细节的校验变化，这种配置已经不能作为当前教程继续照做。

尤其不要继续复制旧文中的 `deepseek-v4-pro` 或“开启 1M context”设置：它们是当时用于客户端模型目录映射的值，不是当前 DeepSeek 平台可长期依赖的模型契约。原截图只保留在仓库中作为历史记录，不代表当前界面。

以下截图仅展示 2026-04-30 的旧界面，用于识别历史方案，不应作为当前配置步骤：

![Claude 旧版第三方推理配置界面](/assets/images/2026-04-30-macos-claude-deepseek/config.jpg){: loading="lazy" decoding="async" }

![Claude 旧版第三方模型页面](/assets/images/2026-04-30-macos-claude-deepseek/result.jpg){: loading="lazy" decoding="async" }

## 当前可行方向

现在需要在 Claude Desktop 与第三方模型 API 之间增加本地兼容层，至少处理：

- Anthropic 与上游接口之间的请求/响应格式差异；
- Claude Desktop 使用的角色模型与上游实际模型之间的映射；
- 流式响应、工具调用、错误格式和鉴权头；
- 客户端升级后可能变化的模型目录或白名单行为。

2026-07-13 核验到两个仍在维护的方向：

### UpstreamKit

[UpstreamKit](https://github.com/Ltb2539/UpstreamKit) 最新 release 为 v1.1.5。项目提供本地 API 中转、上游模型覆盖、日志和 token 统计；README 同时列出了 Windows GUI 与 macOS 本地打包方式。

它更接近通用的本地接口中转工具。使用时应从项目当前 release 获取程序，并以 README 中的协议类型、上游 URL 和模型映射说明为准。

### CC Switch

[CC Switch](https://github.com/farion1231/cc-switch) 最新 release 为 v3.16.5。项目已把 Claude Desktop 作为独立管理入口，支持通过本地代理网关配置第三方供应商和角色模型映射。

如果本机已经用 CC Switch 管理 Claude Code、Codex 等工具，优先查看当前 release 自带的 Claude Desktop 指南；不要套用旧版界面截图或猜测端口、模型 ID。

## 安全与验证边界

- API Key 只填写在本地工具或目标平台的受控配置中，不要写入文章、截图、shell history 或公开仓库。
- 第三方代理会接触提示词、上下文和模型响应，使用前应检查项目来源、更新记录和本地监听范围。
- “连接测试返回 200”只证明接口可达；还需要实际验证多轮对话、流式输出和工具调用。
- 本文确认的是项目当前仍提供相关能力，不代表任意 Claude Desktop、代理版本和 DeepSeek 模型组合都已经通过端到端测试。

## 参考

- [Claude Desktop 下载](https://claude.ai/download)
- [DeepSeek 开放平台](https://platform.deepseek.com/)
- [UpstreamKit](https://github.com/Ltb2539/UpstreamKit)
- [CC Switch Releases](https://github.com/farion1231/cc-switch/releases)
