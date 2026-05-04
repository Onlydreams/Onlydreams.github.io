---
layout: post
title: "Git 自动代理配置指南"
date: 2026-05-04 13:00:00 +0800
categories: [Git, 代理, 效率]
tags: [git, proxy, ssh]
---

记录 Git HTTP/HTTPS 与 SSH 自动走本地代理的配置方法，覆盖命令行、安装脚本和常见远程仓库访问场景。

---

## 目标

通过统一配置，使以下 Git 相关操作自动走本地代理：

- `git clone https://...`
- `git fetch`、`git pull`、`git push`
- 依赖 Git 下载远程仓库的安装脚本
- 使用 SSH 地址的 Git 操作，例如 `git@github.com:<owner>/<repo>.git`

以下示例均使用脱敏占位符：

```text
HTTP 代理：http://127.0.0.1:<HTTP_PORT>
SOCKS5 代理：socks5://127.0.0.1:<SOCKS_PORT>
```

请将 `<HTTP_PORT>` 和 `<SOCKS_PORT>` 替换为本机代理客户端实际监听的端口。

## Shell 环境变量

将代理环境变量写入 `~/.zshenv`，让非交互 zsh、安装脚本和命令行子进程也能继承代理配置。

```zsh
# 全局代理环境变量，供非交互 zsh 和安装脚本使用
export HTTP_PROXY="http://127.0.0.1:<HTTP_PORT>"
export HTTPS_PROXY="http://127.0.0.1:<HTTP_PORT>"
export ALL_PROXY="socks5://127.0.0.1:<SOCKS_PORT>"

export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"
```

如果只把代理写在 `~/.zshrc`，通常只能覆盖交互式终端。`~/.zshenv` 更适合放置需要被非交互命令继承的环境变量。

## 交互式终端自动启用

可以在 `~/.zshrc` 中保留一个代理开关函数，方便手动启停，同时让新打开的终端自动执行 `proxy on`。

```zsh
PROXY_HTTP="http://127.0.0.1:<HTTP_PORT>"
PROXY_SOCKS5="socks5://127.0.0.1:<SOCKS_PORT>"

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
      echo "Proxy ON"
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
        echo "Proxy: ON"
      else
        echo "Proxy: OFF"
      fi
      ;;
  esac
}

proxy on
```

## Git HTTP/HTTPS 代理

为 Git 全局配置 HTTP/HTTPS 代理后，`https://` 协议的 Git 操作会自动走代理。

```bash
git config --global http.proxy "http://127.0.0.1:<HTTP_PORT>"
git config --global https.proxy "http://127.0.0.1:<HTTP_PORT>"
```

查看当前配置：

```bash
git config --global --get http.proxy
git config --global --get https.proxy
```

取消配置：

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

## Git SSH 代理

Git 使用 SSH 地址时，`http.proxy` 和 `https.proxy` 不会生效，需要在 SSH 配置中为目标域名设置 `ProxyCommand`。

编辑 `~/.ssh/config`：

```sshconfig
Host github.com
  HostName github.com
  User git
  ProxyCommand nc -X connect -x 127.0.0.1:<HTTP_PORT> %h %p
  ConnectTimeout 8
```

如果代理客户端提供的是 SOCKS5 端口，也可以使用：

```sshconfig
Host github.com
  HostName github.com
  User git
  ProxyCommand nc -X 5 -x 127.0.0.1:<SOCKS_PORT> %h %p
  ConnectTimeout 8
```

为了避免 SSH 配置权限过宽，建议设置：

```bash
chmod 600 ~/.ssh/config
```

## 验证

验证 Git HTTPS：

```bash
git ls-remote https://github.com/<owner>/<repo>.git HEAD
```

验证 Git SSH：

```bash
ssh -T git@github.com
git ls-remote git@github.com:<owner>/<repo>.git HEAD
```

验证环境变量：

```bash
env | grep -i '_proxy'
```

## 注意事项

- 代理客户端必须先启动，并确认本地端口处于监听状态。
- 修改 `~/.zshenv` 或 `~/.zshrc` 后，需要重新打开终端才能自动生效。
- 从 GUI 应用启动的进程不一定继承 shell 配置，必要时需要重启对应应用。
- `https://` Git 操作依赖 Git 的 `http.proxy`、`https.proxy` 或 shell 代理环境变量。
- `git@...` SSH 操作依赖 `~/.ssh/config` 中的 `ProxyCommand`。
- 文档中的仓库名、用户名、本地路径和代理端口均已脱敏。
