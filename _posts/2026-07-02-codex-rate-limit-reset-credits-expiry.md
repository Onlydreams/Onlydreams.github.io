---
layout: post
title: "Codex App 重置次数过期时间查询：查看 rate-limit reset credits"
date: 2026-07-02 00:00:00 +0800
categories: [AI, 工具, 配置]
tags: [codex, chatgpt, rate-limit, credits, usage]
status:
  label: 当前可用
  verified: 2026-07-02
  environment: Codex App / ChatGPT 登录 / Windows、macOS 本地凭证
  risk: 需要读取本机 Codex 登录凭证并请求 ChatGPT 后端接口；不要打印、保存或分享 access token。
---

Codex App 里看到的“重置次数”不是普通 5 小时使用窗口，而是单独的 rate-limit reset credits。普通额度可以用 `/status` 看，重置次数的过期时间目前更稳的办法是让 Codex 读取本机登录凭证，查询 `rate-limit-reset-credits` 接口，并输出中文结论和脱敏后的 `available_count`、`expires_at`。

---

## 先分清两种重置

Codex 现在有两类容易混在一起的“重置”：

| 类型 | 看什么 | 常见位置 | 能否代表“还剩几次重置” |
| --- | --- | --- | --- |
| 普通使用额度窗口 | `used_percent`、`window_minutes`、`resets_at` | `/status`、本地会话日志 | 不能 |
| 手动重置次数 / reset credits | `available_count`、每个 credit 的 `expires_at` | ChatGPT 后端接口 | 能 |

官方 Codex 文档里，`/status` 的定位是显示 thread ID、context usage 和 rate limits；Codex pricing 也说明本地消息和 cloud tasks 共享 5 小时窗口，并且可能还有额外 weekly limit。也就是说，`/status` 适合看普通额度什么时候恢复，但不等于“我那几次手动重置什么时候过期”。

ChatGPT 的模型额度逻辑也是类似的：达到某个模型 allowance 后，ChatGPT 会在可用时显示 reset time；达到 allowance 不代表订阅失效，也没有设置可以绕过模型额度。Codex 这边的 reset credits 可以按同样思路理解：重点不是猜窗口，而是看服务端给你的具体过期时间。

## 推荐做法：直接让 Codex 查

在 Codex App 新开一个本地线程，把下面这段提示词贴进去：

```text
请使用本机 Codex 凭证查询 rate-limit reset credits。

操作要求：
1. 读取 `~/.codex/auth.json` 中的 `tokens.access_token`
2. 读取 `~/.codex/auth.json` 中的 `tokens.account_id`
3. 使用 GET 请求：
   `https://chatgpt.com/backend-api/wham/rate-limit-reset-credits`
4. 请求头必须包含：
   `Authorization: Bearer <access_token>`
   `ChatGPT-Account-ID: <account_id>`
   `originator: Codex Desktop`
   `OpenAI-Beta: codex-1`

安全要求：
1. 不要打印、保存或回显 access_token、refresh_token、cookie、Authorization header
2. 不要输出完整 credit id、user id、account id 或其他完整唯一标识符
3. 不要把 token 写入临时文件、日志文件或命令输出
4. 只在当前进程内使用 token
5. 只查询 `/rate-limit-reset-credits`，不要调用 `/rate-limit-reset-credits/consume`

输出要求：
1. 先用中文给一句结论，格式类似：
   `你现在还有 N 次可用重置，最早会在 YYYY-MM-DD HH:mm:ss +0800 过期。`
2. 再输出一个中文表格，表头使用：
   - `可用总数`
   - `状态`
   - `重置类型`
   - `重置类型说明`
   - `获得时间`
   - `过期时间`
3. 表格内容只汇总这些字段：
   - `available_count`
   - 每个 credit 的 `status`
   - `title`
   - `granted_at`
   - `expires_at`
4. `granted_at` 和 `expires_at` 从 UTC 转成本地时间，并标明时区
5. 对 `title` 做一句中文解释，例如把 `Full reset (Weekly + 5 hr)` 解释为“完整重置，覆盖 weekly 和 5 小时窗口”
6. 不输出原始 JSON

错误处理：
1. 如果 HTTP 状态码是 401，说明：凭证失效，或没有正确携带 Authorization header
2. 如果 HTTP 状态码是 403 或账号不匹配，说明：可能缺少 `ChatGPT-Account-ID` / `OpenAI-Beta: codex-1`，或当前 token 不属于这个 account
3. 如果网络/SSL/沙箱失败，说明失败原因，并在需要时请求非沙箱网络执行；例如 Windows / Codex 沙箱里出现 `Authentication failed, see inner exception`，不一定代表 token 已失效
4. 如果返回结构和预期不一致，只说明缺失字段，不打印完整响应
```

正常结果应该类似这样：

你现在还有 4 次可用重置，最早会在 2026-08-01 20:00:00 +0800 过期。

| 可用总数 | 状态 | 重置类型 | 重置类型说明 | 获得时间 | 过期时间 |
| --- | --- | --- | --- | --- | --- |
| 4 | available | Full reset (Weekly + 5 hr) | 完整重置，覆盖 weekly 和 5 小时窗口 | 2026-07-02 20:00:00 +0800 | 2026-08-01 20:00:00 +0800 |

这里真正要看的就是 `expires_at`。如果有多条 credit，就看每一条自己的过期时间，不要默认它们一定同一天失效。

`title` 是服务端返回的英文文案，可能是 `Full reset (Weekly + 5 hr)` 这类描述，也可能随着产品调整而变化。它适合帮助你判断这次 reset 覆盖的额度类型，但不要把某个固定 title 当成接口契约。英文不熟的话，重点看中文结论、`重置类型说明` 和 `过期时间`。

## 为什么不用 `/status`

`/status` 能看普通 Codex rate limits。例如本地会话日志里的 `token_count` 事件会带出这样的结构：

```json
{
  "rate_limits": {
    "limit_id": "codex",
    "primary": {
      "used_percent": 21.0,
      "window_minutes": 300,
      "resets_at": 1783011581
    },
    "secondary": {
      "used_percent": 37.0,
      "window_minutes": 10080,
      "resets_at": 1783402343
    }
  }
}
```

这能说明两件事：

- `primary.window_minutes: 300` 是 5 小时窗口。
- `secondary.window_minutes: 10080` 是 7 天窗口。

但它没有暴露 reset credits 的 `expires_at`。所以如果你问的是“普通额度什么时候恢复”，看 `/status` 或日志里的 `resets_at`；如果问的是“限速弹窗里还剩的几次重置什么时候过期”，要查 `rate-limit-reset-credits`。

## 安全边界

这件事的风险点只有一个：`~/.codex/auth.json` 里有本机登录 token。

不要把 token 粘给别人，不要让脚本把 token 写进临时文件，不要把原始 JSON 直接贴到公开 issue、博客或聊天记录里。只输出 `available_count`、`status`、`title`、`granted_at`、`expires_at` 这几个字段，以及基于这些字段生成的中文解释就够了。

还要注意：查询接口和消费接口不是一回事。`GET /wham/rate-limit-reset-credits` 只是查看 banked reset 信息；`POST /wham/rate-limit-reset-credits/consume` 会使用一次 reset。这里只需要查询，不要调用 `consume`。

还有一个现实边界：`https://chatgpt.com/backend-api/wham/rate-limit-reset-credits` 不是公开稳定 API。它当前能查到需要的信息，但 OpenAI 以后可能改路径、改字段，或者把这个信息放进 Codex App 的正式 UI。openai/codex#28963 和 #29618 都在请求把 reset credits 明细暴露到受支持的 Codex surface；在此之前，这个接口只能算临时 workaround。社区里也有人提到 reset credits 常见是 30 天计时，但不要把它当固定规则，实际以接口返回的 `expires_at` 为准。

## 参考来源

- [Codex App Commands](https://developers.openai.com/codex/app/commands)：`/status` 用于显示 thread ID、context usage 和 rate limits。
- [Codex Pricing](https://developers.openai.com/codex/pricing)：Codex 包含在 ChatGPT 计划中，本地消息和 cloud tasks 使用 5 小时窗口，且可能有额外 weekly limit。
- [About ChatGPT Pro tiers](https://help.openai.com/en/articles/9793128-about-chatgpt-pro-plans)：ChatGPT 达到某个模型 allowance 后，模型可能暂时不可用，ChatGPT 会在可用时显示 reset time。
- [openai/codex#28963](https://github.com/openai/codex/issues/28963)：请求在 Codex 里暴露 banked reset credits 的明细，并给出了包含 `OpenAI-Beta: codex-1` 的查询头部示例。
- [openai/codex#29618](https://github.com/openai/codex/issues/29618)：社区请求在 Codex 受支持的 surface 中暴露 reset credits 的过期时间和明细。
- [Reddit r/codex: Codex Banked Reset Information](https://www.reddit.com/r/codex/comments/1uaf4vy/codex_banked_reset_information/)：社区验证了查询接口、必要请求头和查询/消费接口的区别。
