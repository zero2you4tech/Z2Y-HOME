---
name: zero2you-site-manager
description: Update the Zero2You OPC product website. Use when changing app metadata, versions, release notes, install or support instructions, product updates, journal articles, or publishing content so the GitHub Pages site rebuilds.
metadata:
  short-description: Manage Zero2You product website content
---

# Zero2You Site Manager

Use this skill for the official Zero2You product website at `zero2you4tech/Z2Y-HOME`. It keeps product metadata, release notes, support content, and articles coherent, bilingual, and publishable through the existing GitHub Pages workflow.

## Resolve the repository

Prefer `$Z2Y_HOME_REPO`. If it is not set, use `~/WorkSpace/Project/Web/zero2you4tech/Z2Y-HOME`. Verify the directory contains `_config.yml`, `_data/apps.yml`, and a Git remote pointing to `zero2you4tech/Z2Y-HOME`.

If the repository cannot be resolved, stop and report the expected path. Do not create a second copy of the site.

## Ground every content change

Read the narrowest existing source before editing:

- App metadata: `_data/apps.yml`
- App routing stub: `_apps/<app-id>.md`
- UI labels: `_data/ui.yml`
- Release posts: `_posts/*` with `categories: [app-update]`
- Journal posts: `_posts/*` with `categories: [article]`
- Schema details: `references/content-schema.md`

Use authoritative release information when a version or date is involved:

- App Store: Apple lookup API for the app id in the existing entry.
- GitHub: repository and latest release metadata for GitHub-distributed products.
- Explicit user-provided release notes.

Never invent a version, release date, capability, requirement, or support promise. If the source does not confirm a field, leave it empty or mark the product as `in-development` or `preview`.

## Update app metadata

Use the deterministic helper instead of rewriting YAML by hand:

1. Create a temporary JSON patch containing only the fields to change.
2. Run:

```bash
ruby .codex/skills/zero2you-site-manager/scripts/upsert_app.rb \
  --repo "$Z2Y_HOME_REPO" \
  --app z2y-ai \
  --patch /tmp/z2y-ai-patch.json \
  --create-page
```

3. Keep both language values for every user-facing field. `zh` and `en` are required for names, taglines, summaries, descriptions, prices, requirements, installation steps, and highlights.

App pages are generated from `_data/apps.yml` through the `_apps/` collection. A new app must have both an app entry and an `_apps/<id>.md` page. The page front matter is intentionally minimal:

```yaml
---
layout: app
app_id: "new-app-id"
---
```

## Record a release

Create a release post when a version change is meaningful, user-visible, or requested:

```bash
ruby .codex/skills/zero2you-site-manager/scripts/create_release_post.rb \
  --repo "$Z2Y_HOME_REPO" \
  --app z2y-ai \
  --version 1.2.0 \
  --date 2026-10-12 \
  --title "Z2Y AI Manager 更新至 1.2.0" \
  --title-en "Z2Y AI Manager reaches 1.2.0" \
  --summary-zh "本次更新..." \
  --summary-en "This release..." \
  --body-zh "详细说明..." \
  --body-en "Release details..."
```

The post must include `app_id`, `version`, `categories: [app-update]`, matching `title_en`, and bilingual body sections using `data-lang="zh"` and `data-lang="en"` — each block must also carry `markdown="1"`, because kramdown does not parse markdown inside HTML blocks by default (links and bold would otherwise render as plain text). `create_release_post.rb` writes the attribute and `validate_site_content.rb` rejects posts that omit it.

Also update the `version`, `version_label`, `updated_at`, links, changelog, and any changed requirements in `_data/apps.yml`.

## Add a journal article

Add an article as `_posts/YYYY-MM-DD-slug.md` with:

```yaml
categories:
  - article
title_en: "..."
excerpt_en: "..."
author_profile: false
share: false
related: false
```

Use two top-level body sections:

```html
<div data-lang="zh" markdown="1">...</div>
<div data-lang="en" markdown="1">...</div>
```

Do not use this workflow for the legacy sample posts already in `_posts`; leave them untouched.

## Validate and publish

Always run:

```bash
ruby .codex/skills/zero2you-site-manager/scripts/validate_site_content.rb "$Z2Y_HOME_REPO"
```

Before publishing, inspect `git diff` and confirm that only intended files changed. The GitHub Actions workflow builds and deploys on pushes to `main`, so publish only when the user explicitly asks to push:

```bash
.codex/skills/zero2you-site-manager/scripts/publish_site.sh \
  --message "Update Z2Y AI Manager 1.2.0" \
  --push \
  _data/apps.yml \
  _apps/z2y-ai.md \
  _posts/2026-10-12-z2y-ai-1-2-0.md
```

`publish_site.sh` validates, stages only the supplied paths, commits, pushes `main`, and tries to report the latest Pages workflow run. If validation or push fails, report the exact failure and leave the working tree intact.

## Completion checks

- The app appears in `_data/apps.yml` exactly once.
- Every app has a matching `_apps/<id>.md`.
- Every public field has Chinese and English content.
- New release posts reference an existing app and the version/date agree with the app entry.
- `validate_site_content.rb` exits successfully.
- A GitHub Pages build is triggered after a push to `main`.
