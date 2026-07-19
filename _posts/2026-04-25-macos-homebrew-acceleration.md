---
layout: post
title: "macOS 开发环境加速：Homebrew 镜像、pip 源与终端代理配置"
date: 2026-04-25 17:00:00 +0800
updated: 2026-07-20
categories: [开发工具, 网络与代理]
tags: [homebrew, pip, proxy, mirror, zsh]
series: [network-proxy, macos-tooling]
series_order:
  network-proxy: 1
  macos-tooling: 1
status:
  label: 待复核
  verified: 2026-07-20
  environment: macOS（Intel）/ Homebrew / pip / zsh / Clash Verge TUN
  risk: USTC 镜像的连通性、Git 协议和远端提交已核验，但尚未重新完成一次 brew update；配置会修改包管理源和 shell 环境。
---

记录本次为加速 macOS 开发环境所做的配置，涵盖 Homebrew、pip 以及终端代理。2026-07-20 已将 Homebrew 主仓库、API 和 Bottles 统一到中科大 USTC 镜像，并在 Clash Verge TUN 模式下移除了 Git 全局代理。镜像可用性和速度会随网络变化，本文把当前配置、故障核验与 2026-04-25 的历史测速样本分开说明。

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

### 2. 统一配置 USTC 镜像

Homebrew 的主仓库、JSON API 和预编译 Bottles 是三条不同链路。当前配置把它们统一到 USTC，避免主仓库与下载源混用不同镜像。

`~/.zshrc` 中添加：

```bash
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
```

让配置在当前终端生效：

```bash
source ~/.zshrc
```

如果 Homebrew 已安装，并且主仓库仍指向其他镜像，可以先立即修改现有 `origin`：

```bash
git -C "$(brew --repository)" remote set-url origin \
  "https://mirrors.ustc.edu.cn/brew.git"
```

`HOMEBREW_BREW_GIT_REMOTE` 是持久配置：以后运行 `brew update` 时，Homebrew 会继续把主仓库远端设置为这个地址。只执行一次 `git remote set-url` 而不保留环境变量，后续配置可能再次漂移。

检查当前生效值与远端连通性：

```bash
brew config
git -C "$(brew --repository)" remote get-url origin
git ls-remote "https://mirrors.ustc.edu.cn/brew.git" refs/heads/main
```

确认无误后再执行完整更新：

```bash
brew update --verbose
```

2026-07-20 的现场核验已确认 USTC 支持 Git smart HTTP，且当时 `main` 提交与 GitHub 官方一致；但没有继续执行完整的 `brew update`，所以本文暂时标记为“待复核”。第三方镜像存在同步延迟和供应链风险，必要时应恢复官方地址。

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

### TUN 模式：移除重复的 Git 全局代理

Clash Verge 已开启 TUN 时，网络流量由 TUN 接管，不需要再让 Git 固定走本地 HTTP 端口。两者同时存在会形成重复代理，也会让排障时难以区分是 TUN、Git 配置还是镜像本身的问题。

移除 Git 全局代理：

```bash
git config --global --unset-all http.proxy 2>/dev/null || true
git config --global --unset-all https.proxy 2>/dev/null || true
```

确认没有残留：

```bash
git config --global --get-regexp '^(http|https)\.proxy$'
```

预期没有输出。这里只移除 Git 的全局代理项，不会关闭 Clash Verge、TUN 或系统代理。

### 非 TUN 模式：按需设置终端代理

如果没有开启 TUN，而是希望当前终端中的 `git`、`curl` 和 `brew` 临时走本地代理，可在 `~/.zshrc` 中添加开关函数。这里仅设置当前 shell 的环境变量，不再写入 Git 全局配置：

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
      echo "Proxy ON  ->  $PROXY_HTTP"
      ;;
    off)
      unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
      unset http_proxy https_proxy all_proxy
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

开启 TUN 后不要再自动执行 `proxy on`。如果必须长期为 Git 单独配置代理，应记录配置来源，并避免同时维护 shell 环境变量、Git 全局代理和 TUN 三套入口。

---

## 三、pip 加速

配置阿里云 PyPI 镜像：

```bash
pip3 config set global.index-url "https://mirrors.aliyun.com/pypi/simple/"
```

镜像使用有效 HTTPS 证书时不需要设置 `trusted-host`。配置文件的实际位置会受操作系统、用户级/全局级和虚拟环境影响，可用 `pip3 config debug` 查看当前生效文件，不要只依赖固定路径。

---

## 四、一次 `brew update` 高 CPU 空转的排查

2026-07-20，`brew update --verbose` 长时间停在 Homebrew 主仓库的 `git fetch`。现场现象不是网络缓慢，而是 `git-remote-https` 持续占用约 99% CPU，TCP 队列为空，并产生大量零字节临时对象。

进一步检查发现，当时使用的腾讯镜像没有返回 Git smart HTTP 所需的 `application/x-git-upload-pack-advertisement`，Git 因而回退到逐个对象抓取的 dumb HTTP 路径。切换镜像前的测速数字即使很快，也不能证明完整 `git fetch` 协议兼容。

当日对比结果如下，只代表核验时点：

| 镜像源 | smart HTTP | 当时结果 |
| ------ | ---------- | -------- |
| USTC | 正常 | `main` 提交与 GitHub 官方一致，采用 |
| 清华 TUNA | 正常 | 可用，但当时有轻微同步延迟 |
| 腾讯镜像 | 异常 | 回退 dumb HTTP，导致高 CPU 空转 |

遇到类似问题时，应先检查 `brew update --verbose` 卡在哪个 Git 子命令，再比较镜像的协议响应和远端提交；不要只根据首页响应时间或一次 `git ls-remote` 耗时判断镜像可用性。

---

## 五、2026-04-25 的镜像速度样本

以下结果只代表当时机器和网络环境，用于说明“应在自己的真实链路上比较”，不构成 2026-07-20 的镜像排名。腾讯源当时的 `git ls-remote` 用时很短，但后续完整更新暴露了协议兼容问题，因此不再推荐。

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

## 六、当前环境信息

- **系统**：macOS（Intel）
- **Shell**：zsh
- **Homebrew**：以运行时稳定版本为准
- **Homebrew 镜像**：USTC（主仓库、API、Bottles）
- **代理工具**：Clash Verge（TUN 模式）
- **Git 全局代理**：未设置

## 参考

- [Homebrew 环境变量说明](https://docs.brew.sh/Manpage)
- [Homebrew 自动更新说明](https://docs.brew.sh/FAQ)
- [中科大 Homebrew Bottles 镜像帮助](https://mirrors.ustc.edu.cn/help/homebrew-bottles.html)
- [中科大 brew.git 镜像帮助](https://mirrors.ustc.edu.cn/help/brew.git.html)
- [Git HTTP 协议说明](https://git-scm.com/docs/gitprotocol-http)
- [pip 配置命令](https://pip.pypa.io/en/stable/cli/pip_config/)
