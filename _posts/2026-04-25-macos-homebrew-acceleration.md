---
layout: post
title: "macOS 开发环境加速：Homebrew 镜像、pip 源与终端代理配置"
date: 2026-04-25 17:00:00 +0800
updated: 2026-07-13
categories: [开发工具, 网络与代理]
tags: [homebrew, pip, proxy, mirror, zsh]
series: [network-proxy, macos-tooling]
series_order:
  network-proxy: 1
  macos-tooling: 1
status:
  label: 当前可用
  verified: 2026-07-13
  environment: macOS / Homebrew / pip / zsh
  risk: 会修改包管理源、终端代理和 shell 配置，执行前建议备份原配置。
---

记录本次为加速 macOS 开发环境所做的配置，涵盖 Homebrew、pip 以及终端代理。镜像可用性和速度会随网络变化，本文把 Homebrew 当前支持的配置方式与 2026-04-25 的历史测速样本分开说明。

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

#### Brew 自身仓库

Homebrew 当前提供 `HOMEBREW_BREW_GIT_REMOTE` 环境变量指定自身仓库镜像。继续使用中科大镜像时，可在 `~/.zshrc` 中添加：

```bash
export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git
```

这种方式比直接修改 `brew --repo` 的 Git remote 更符合 Homebrew 当前提供的配置接口，也便于临时撤销。要恢复官方仓库，删除该环境变量后重新打开终端即可。

### 3. 关闭自动更新

`~/.zshrc` 中添加：

```bash
export HOMEBREW_NO_AUTO_UPDATE=1
```

关闭后，`brew install` 等命令不再自动刷新公式和 cask 元数据，但也会延迟功能与安全更新。更保守的做法是保留自动更新，或使用 `HOMEBREW_AUTO_UPDATE_SECS` 延长检查间隔：

```bash
export HOMEBREW_AUTO_UPDATE_SECS=86400
```

如果选择完全关闭，仍应定期手动运行 `brew update`。

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
```

镜像使用有效 HTTPS 证书时不需要设置 `trusted-host`。配置文件的实际位置会受操作系统、用户级/全局级和虚拟环境影响，可用 `pip3 config debug` 查看当前生效文件，不要只依赖固定路径。

---

## 四、2026-04-25 的镜像速度样本

以下结果只代表当时机器和网络环境，用于说明“应在自己的真实链路上比较”，不构成 2026-07-13 的镜像排名。

### Homebrew 仓库镜像对比

| 镜像源     | git ls-remote 耗时 |
| ---------- | ------------------ |
| 清华源     | 28.87 秒           |
| **腾讯源** | **0.37 秒**        |

### PyPI 镜像对比

| 镜像源     | 响应时间    |
| ---------- | ----------- |
| 官方 PyPI  | 12.74 秒    |
| 中科大     | 0.14 秒     |
| **阿里云** | **0.23 秒** |
| 腾讯云     | 0.34 秒     |
| 清华       | 0.38 秒     |
| 豆瓣       | 0.40 秒     |

---

## 五、当前环境信息

- **系统**：macOS（Intel）
- **Shell**：zsh
- **Homebrew**：以运行时稳定版本为准
- **代理工具**：本地代理客户端（规则模式）

## 参考

- [Homebrew 环境变量说明](https://docs.brew.sh/Manpage)
- [Homebrew 自动更新说明](https://docs.brew.sh/FAQ)
- [中科大 Homebrew Bottles 镜像帮助](https://mirrors.ustc.edu.cn/help/homebrew-bottles.html)
- [中科大 brew.git 镜像帮助](https://mirrors.ustc.edu.cn/help/brew.git.html)
- [pip 配置命令](https://pip.pypa.io/en/stable/cli/pip_config/)
