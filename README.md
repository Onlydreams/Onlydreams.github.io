# Onlydreams

个人技术博客，记录 AI Agent 工具链、开发环境与网络排障实践。

站点：https://www.dayjia.com

## 本地开发

[`.ruby-version`](.ruby-version) 记录 CI 的 Ruby 基线版本；本地项目脚本也接受同一 minor 系列中不低于该基线的 patch 版本。仓库操作统一使用项目脚本。

macOS / Linux：

```bash
bash bin/setup
bash bin/test
bash bin/serve
```

Windows PowerShell：

```powershell
.\bin\setup.ps1
.\bin\test.ps1
.\bin\serve.ps1
```

完整的开发、内容与验证规范见 [`AGENTS.md`](AGENTS.md)。
