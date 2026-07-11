# Onlydreams.github.io

Onlydreams 的 Jekyll 技术博客。

🌐 站点：https://www.dayjia.com

## 跨机器本地开发

这个仓库固定使用 [`.ruby-version`](.ruby-version) 指定的 Ruby 版本，以及 `Gemfile.lock` 指定的 Bundler 和 gems。不要在仓库内直接运行裸 `bundle`；统一使用 `bin/setup`、`bin/test` 入口。它们会：

- 只选择匹配 `.ruby-version` 的 Ruby；
- 在当前进程清除外部 `BUNDLE_PATH` / `BUNDLE_GEMFILE`，让仓库的 `.bundle/config` 生效；
- 使用 lockfile 指定的 Bundler 版本；
- 把站点依赖安装到忽略的 `vendor/bundle`；Bundler 本身只安装到匹配的 Ruby 版本一次。

### 每台机器一次性准备

**Windows（推荐 RubyInstaller）**

1. 从 [RubyInstaller 下载页](https://rubyinstaller.org/downloads/) 安装与 `.ruby-version` 完全一致的 **Ruby+Devkit x64**；不要覆盖已有的 Ruby 4.x。
2. 安装器结束后运行一次 `ridk install`，选择 MSYS2 基础组件。Devkit 让 `sassc` 等原生 gem 能正常安装。
3. 在仓库根目录运行：

```powershell
.\bin\setup.ps1
```

脚本会优先找到标准 RubyInstaller 目录中对应的 Ruby；若安装在自定义位置，可只为当前会话指定：

```powershell
$env:ONLYDREAMS_RUBY = 'D:\tools\Ruby33-x64\bin\ruby.exe'
.\bin\setup.ps1
```

**macOS / Linux**

用你的版本管理器或包管理器安装 `.ruby-version` 中的准确版本，再确保该版本位于当前 shell 的 `PATH`。例如 Homebrew：

```bash
brew install ruby@3.3
export PATH="$(brew --prefix ruby@3.3)/bin:$PATH"
bash bin/setup
```

如果 Ruby 位于非标准位置，可只为当前 shell 指定：

```bash
export ONLYDREAMS_RUBY="/custom/ruby-3.3.11/bin/ruby"
bash bin/setup
```

### 日常命令

```bash
bash bin/test
```

```powershell
.\bin\test.ps1
```

完整测试会构建站点，并运行站点功能与文章内容健康检查。需要本地预览时也使用仓库入口：

```bash
bash bin/serve
```

```powershell
.\bin\serve.ps1
```

### 排错

- `expected Ruby ...`：当前 Ruby 不匹配；先安装并选择 `.ruby-version` 指定版本，不要用 Ruby 4.x 代替。
- `Bundler ... is missing`：运行对应平台的 `bin/setup`，它会安装 lockfile 指定的 Bundler。
- 不要把 `BUNDLE_PATH` 写进系统环境变量、PowerShell profile 或 shell rc；仓库依赖由 `.bundle/config` 的 `vendor/bundle` 管理。
