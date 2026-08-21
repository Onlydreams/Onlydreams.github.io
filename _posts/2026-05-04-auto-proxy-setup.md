---
layout: post
title: "Git HTTP/SSH 代理配置：先区分 TUN、HTTPS 与 SSH"
date: 2026-05-04 13:00:00 +0800
updated: 2026-08-21
categories: [网络与代理, 开发工具]
tags: [git, proxy, ssh, zsh, github, http-proxy]
series: [network-proxy]
series_order:
  network-proxy: 2
status:
  label: 当前可用
  verified: 2026-07-13
  environment: Git HTTP/SSH / zsh / 本地代理
  risk: 会修改 Git、SSH 或 shell 代理配置，执行前建议记录当前配置。
---

Git 访问 GitHub 失败时，不要先把 shell 环境变量、Git 全局代理和 SSH `ProxyCommand` 全部打开。TUN 已经接管流量时，额外配置 Git 代理通常只会增加一层重复链路；只有非 TUN、特定 SSH 连接或安装脚本没有继承代理时，才需要分别处理。

---

## 先说结论

Git 没有一套同时控制所有传输方式的“总开关”。真正需要区分的是四条链路：

| 当前场景 | 优先做法 | 不建议默认做什么 |
|---|---|---|
| Clash Verge 等客户端已开启 TUN | 先让 Git 直接使用系统网络，确认没有残留的 Git 全局代理 | 不要再固定写入 `http.proxy` 和 `https.proxy` |
| 没有 TUN，只想让当前终端临时走代理 | 设置当前 shell 的代理环境变量，用完后关闭 | 不要为了偶发访问把代理永久写进所有 shell |
| 长期使用 `https://` Git 地址，且网络链路确实需要本地代理 | 单独配置 Git HTTP/HTTPS 代理 | 不要误以为它会影响 `git@github.com:...` |
| 使用 `git@github.com:...` SSH 地址 | 在 `~/.ssh/config` 中为目标 Host 配置 `ProxyCommand` | 不要只改 Git 的 `http.proxy` |

原则只有一个：先确认哪一层已经接管流量，再只补缺失的那一层。多配几套代理不会自动更稳定，反而会让连接失败时难以判断问题出在 TUN、shell、Git 还是 SSH。

## 先检查 TUN 和现有配置

如果代理客户端已经开启 TUN，先检查 Git 是否还保留了旧的全局代理：

```bash
git config --global --get-regexp '^(http|https)\.proxy$'
```

确认 TUN 可以正常访问目标后，可以移除重复配置：

```bash
git config --global --unset-all http.proxy 2>/dev/null || true
git config --global --unset-all https.proxy 2>/dev/null || true
```

这里只移除 Git 自己的全局代理项，不会关闭 TUN 或系统代理。删除前应记录原值；如果当前网络明确依赖 Git 单独代理，不要机械照做。

## 本文覆盖的操作

在确认需要额外代理后，下面的配置分别覆盖：

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

## 可选：让所有 zsh 子进程继承代理

只有在确实需要非交互 zsh、安装脚本和所有命令行子进程默认继承代理时，才把代理环境变量写入 `~/.zshenv`。这会扩大影响范围；日常使用更推荐下一节的按需开关。TUN 已经接管流量时，不需要再写这组变量。

```zsh
# 全局代理环境变量，供非交互 zsh 和安装脚本使用
export HTTP_PROXY="http://127.0.0.1:<HTTP_PORT>"
export HTTPS_PROXY="http://127.0.0.1:<HTTP_PORT>"
export ALL_PROXY="socks5://127.0.0.1:<SOCKS_PORT>"

export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"
```

如果只把代理写在 `~/.zshrc`，通常只能覆盖交互式终端。不要同时在多个 shell 文件里重复维护同一组代理值。

## 交互式终端自动启用

非 TUN 环境可以在 `~/.zshrc` 中保留一个代理开关函数，方便手动启停。如果并非每次打开终端都需要代理，不要在文件末尾自动执行 `proxy on`，改为需要时手动开启。

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
      git config --global --unset-all http.proxy 2>/dev/null || true
      git config --global --unset-all https.proxy 2>/dev/null || true
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

# 需要时手动执行：proxy on
```

## Git HTTP/HTTPS 代理

只有确认 `https://` Git 链路需要长期固定走本地代理时，才设置下面的全局项。它不会作用于 SSH 地址，也不应与已经正常工作的 TUN 机械叠加。

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
git config --global --unset-all http.proxy 2>/dev/null || true
git config --global --unset-all https.proxy 2>/dev/null || true
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
- TUN、shell 环境变量、Git 全局代理和 SSH `ProxyCommand` 是不同接管层；优先只保留完成当前目标所需的最少配置。
- 修改 `~/.zshenv` 或 `~/.zshrc` 后，需要重新打开终端才能自动生效。
- 从 GUI 应用启动的进程不一定继承 shell 配置，必要时需要重启对应应用。
- `https://` Git 操作依赖 Git 的 `http.proxy`、`https.proxy` 或 shell 代理环境变量。
- `git@...` SSH 操作依赖 `~/.ssh/config` 中的 `ProxyCommand`。
- 文档中的仓库名、用户名、本地路径和代理端口均已脱敏。

## 参考

- [Git `http.proxy` 配置说明](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpproxy)
- [Git SSH 传输说明](https://git-scm.com/docs/git#Documentation/git.txt-codeGITSSHCOMMANDcode)
