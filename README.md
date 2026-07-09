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

## 内容维护

- 新文章放在 `_posts/`，文件名为 `YYYY-MM-DD-slug.md`。
- 每篇文章必须包含 `layout`、`title`、`date`、`categories`、`tags` 和 `status` front matter。
- 不提交 `_site/`、`vendor/`、本地缓存或环境文件。
- 发布前运行 `./bin/test`；公共文章不得包含密钥、Token、个人路径或真实代理节点信息。

更完整的站点协作规范见 [AGENTS.md](AGENTS.md)。
