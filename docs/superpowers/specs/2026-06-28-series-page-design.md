# Series Page Design

## Goal

Add a lightweight `/series/` page for grouping related posts into guided topic collections. The first version should help readers find connected articles without adding Jekyll plugins, runtime JavaScript, or a larger visual redesign.

## Scope

In scope:

- Add a `/series/` page that lists posts grouped by `series` front matter keys.
- Add a `_data/series.yml` file for stable series titles, descriptions, and display order.
- Add front matter metadata to existing posts that already belong to clear topic series.
- Add navigation entry text for the new page.
- Add focused styles that match the current taxonomy and post list design.
- Add tests for generated page content and navigation.

Out of scope:

- Article status blocks.
- Search ranking or highlighting changes.
- Per-post "other posts in this series" navigation.
- Newsletter, Open Graph image generation, analytics, or visual redesign.
- Any new Jekyll plugin or dependency.

## Content Model

Series metadata lives in `_data/series.yml`:

```yaml
- key: ai-agent
  title: AI Agent 工作流
  description: Codex、Claude、Skills 与 Agent 协作规则相关笔记。
```

Posts may define these optional front matter fields:

```yaml
series: [ai-agent, macos-tooling]
series_order:
  ai-agent: 2
  macos-tooling: 3
```

Field behavior:

- `series` is an array of stable machine keys used for grouping.
- `_data/series.yml` provides the human-readable title and description shown on `/series/`.
- `series_order` is an optional map that controls ordering inside each series. Lower numbers appear first.
- Posts without `series` are ignored by the series page.
- If a post references a key not present in `_data/series.yml`, it should not create a visible section in the first version.
- If `series_order` is missing for a key, the post sorts after ordered posts by date.

## Initial Series

Add current posts to these first groups:

- `ai-agent` / `AI Agent 工作流`
  - Skillshare guide
  - AGENTS.md configuration guide
  - Codex Desktop GPU rendering bug
  - World Cup Predictor skill article
- `network-proxy` / `网络与代理排障`
  - macOS Homebrew acceleration
  - Git HTTP/SSH auto proxy setup
  - Clash Verge GitHub node speed test
  - Network diagnosis prompt
- `macos-tooling` / `macOS 开发工具链`
  - macOS Homebrew acceleration
  - Claude Desktop DeepSeek setup
  - Codex Desktop GPU rendering bug

Posts may belong to more than one reader path when that improves discovery. Keep the number of series per post small and intentional.

## Page Behavior

The `/series/` page should:

- Use the existing `page` layout.
- Render one section per entry in `_data/series.yml` that has matching posts.
- Show the series title, article count, and a short list of posts.
- Show each post title, date, optional updated date, excerpt, and up to five tags.
- Sort sections by the order in `_data/series.yml`.
- Sort posts in a section by `series_order`, then by post date.
- Avoid client-side rendering so the page works in generated static HTML.

## Navigation

Add "专题" to the visible site navigation alongside existing pages. The link target is `/series/`.

## Styling

Reuse the existing restrained site language:

- Full-width page content with constrained inner width from the current layout.
- Series sections should look closer to taxonomy sections than marketing cards.
- Individual post entries may reuse post-card-like spacing, but avoid nested cards.
- Mobile layout must keep titles, dates, tags, and excerpts from overlapping.

## Testing

Extend `test/site_features_test.rb` to assert:

- `_site/series/index.html` exists and contains "专题".
- The page lists the initial series titles.
- Representative posts appear under the expected series.
- The site navigation contains a link to `/series/`.
- Existing build and feature tests continue to pass with `.\bin\test.ps1`.

## Acceptance Criteria

- Running `.\bin\test.ps1` succeeds.
- `/series/` renders in the built site without JavaScript.
- At least the three initial series are visible.
- Existing posts without `series` still build normally.
- No generated `_site/`, cache, dependency, or environment files are committed.
