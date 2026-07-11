# Onlydreams.github.io

Onlydreams 的 Jekyll 技术博客。

🌐 站点：https://www.dayjia.com

## 本地开发

Ruby 版本以 [`.ruby-version`](.ruby-version) 为准。首次安装依赖时，把 Bundler 依赖保存在仓库内：

```bash
bundle config set --local path vendor/bundle
bundle install
```

常用命令：

```bash
bundle exec jekyll serve
bundle exec jekyll build
./bin/test
```

Windows PowerShell 使用：

```powershell
.\bin\test.ps1
```

完整测试会构建站点，并运行站点功能与文章内容健康检查。
