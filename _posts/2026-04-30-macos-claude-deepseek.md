---
layout: post
title: "MacOS Claude 客户端接入 DeepSeek V4 作为第三方模型"
date: 2026-04-25 17:00:00 +0800
categories: [MacOS, 效率]
tags: [claude, deepseek]
---

记录 MacOS 下将 Claude 桌面客户端接入 DeepSeek 作为第三方模型的步骤。

---

## 安装步骤

### 1. 下载 Claude 桌面客户端并安装

前往 Claude 官网下载 MacOS 版桌面客户端，下载完成后按步骤安装。

- 下载地址：[https://claude.ai/download](https://claude.ai/download)
- 安装完成后，首次启动无需登录 Claude 账号。

### 2. 获取 DeepSeek API Key

登录 DeepSeek 开放平台，创建并复制一个 API Key，稍后会在 Claude 客户端中使用。

- 访问：[https://platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)
- 点击「创建 API Key」，填写名称后生成。
- **复制并妥善保存 API Key**，页面关闭后将无法再次查看。

### 3. 打开 Claude 客户端的 Developer 模式，修改配置

1. 启动 Claude 客户端，在菜单栏选择 `Help` → `Troubleshooting` → `Enable Developer Mode`，此时菜单栏会出现 `Developer` 选项。
2. 打开 `Developer` → `Configure Third-Party Inference...`，在默认的 `Connection` 中修改 `Gateway` 模式下的配置：

   ```text
   Gateway BaseURL:     https://api.deepseek.com/anthropic
   Gateway API key:     刚生成的 DeepSeek API key
   Gateway Auth Scheme: bearer
   ```

3. 继续往下拉，在 `Model list` 中点击 `Add`，`Model ID` 输入 `deepseek-v4-pro`，并开启 `Offer 1M-context variant` 选项。

   ![Claude 配置](/assets/images/2026-04-30-macos-claude-deepseek/config.jpg)

4. 配置完成后，点击 `Apply locally`，再点击 `Relaunch Now` 等待应用重启完成，即可使用 DeepSeek V4 作为第三方模型进行对话。

   ![Claude 页面](/assets/images/2026-04-30-macos-claude-deepseek/result.jpg)
