---
layout: post
title: "macOS 开发环境加速配置全记录"
date: 2026-04-25 17:00:00 +0800
categories: [macOS, Homebrew, 效率]
tags: [homebrew, pip, proxy, mirror]
---

记录本次为加速 macOS 开发环境所做的全部配置，涵盖 Homebrew、pip 以及终端代理。

---

## 一、Homebrew 加速

### 1. 清理第三方 Tap

删除了两个从 GitHub 拉取的第三方 tap，避免 `brew update` 时访问外网：

```bash
# 已删除的 tap
brew untap antoniorodr/memo
brew untap qoderai/qoder
```

删除原因：这两个 tap 没有镜像，每次 `brew update` 都需要直接从 GitHub 拉取。

### 2. 配置国内镜像源

#### Bottles + API（中科大源）

`~/.zshrc` 中添加：

```bash
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
export HOMEBREW_API_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/api
```

#### Brew 自身仓库（腾讯源）

Homebrew 核心代码仓库改用腾讯云镜像：

```bash
git -C "$(brew --repo)" remote set-url origin https://mirrors.cloud.tencent.com/homebrew/brew.git
```

选择原因：实测腾讯源 `git ls-remote` 仅需 **0.37 秒**，而清华源需要 **28.87 秒**。

### 3. 关闭自动更新

`~/.zshrc` 中添加：

```bash
export HOMEBREW_NO_AUTO_UPDATE=1
```

原因：`brew update` 即使在国内镜像下，由于 Homebrew 自身 git 仓库体积大，`git fetch` 仍然很慢。关闭后，`brew install` 不再自动触发更新。

---

## 二、终端代理配置（Clash Verge）

`~/.zshrc` 中添加代理开关函数：

```bash
# 替换 <你的代理端口> 为你实际使用的端口，如 7890 / 7897 / 8080 等
PROXY_HTTP="http://127.0.0.1:<你的代理端口>"
PROXY_SOCKS5="socks5://127.0.0.1:<你的代理端口>"

proxy() {
  case "$1" in
    on)
      export HTTP_PROXY="$PROXY_HTTP"
      export HTTPS_PROXY="$PROXY_HTTP"
      export ALL_PROXY="$PROXY_SOCKS5"
      export http_proxy="$PROXY_HTTP"
      export https_proxy="$PROXY_HTTP"
      export all_proxy="$PROXY_SOCKS5"
      git config --global http.proxy "$PROXY_HTTP"
      git config --global https.proxy "$PROXY_HTTP"
      echo "Proxy ON  ->  $PROXY_HTTP"
      ;;
    off)
      unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
      unset http_proxy https_proxy all_proxy
      git config --global --unset http.proxy
      git config --global --unset https.proxy
      echo "Proxy OFF"
      ;;
    status|*)
      if [[ -n "$HTTP_PROXY" ]]; then
        echo "Proxy: ON  ($HTTP_PROXY)"
      else
        echo "Proxy: OFF"
      fi
      ;;
  esac
}
```

用法：

```bash
proxy on     # 开启终端代理
proxy off    # 关闭终端代理
proxy status # 查看当前状态
```

作用：让终端中的 `git`、`curl`、`brew` 等命令也能走 Clash Verge 代理，解决 GitHub 访问慢/超时的问题。

---

## 三、pip 加速

配置阿里云 PyPI 镜像：

```bash
pip3 config set global.index-url "https://mirrors.aliyun.com/pypi/simple/"
pip3 config set global.trusted-host "mirrors.aliyun.com"
```

配置文件位置：`~/.config/pip/pip.conf`

---

## 四、镜像源速度实测

### Homebrew 仓库镜像对比

| 镜像源 | git ls-remote 耗时 |
|---|---|
| 清华源 | 28.87 秒 |
| **腾讯源** | **0.37 秒** |

### PyPI 镜像对比

| 镜像源 | 响应时间 |
|---|---|
| 官方 PyPI | 12.74 秒 |
| 中科大 | 0.14 秒 |
| **阿里云** | **0.23 秒** |
| 腾讯云 | 0.34 秒 |
| 清华 | 0.38 秒 |
| 豆瓣 | 0.40 秒 |

---

## 五、当前环境信息

- **系统**：macOS (Intel)
- **Shell**：zsh
- **Homebrew**：较新版本
- **代理工具**：本地代理客户端（规则模式）
