# Zero2You Content Schema

## App entry

Each item in `_data/apps.yml` has this shape:

```yaml
- id: z2y-example
  order: 20
  name: { zh: "中文名称", en: "English name" }
  tagline: { zh: "一句话定位", en: "One-line positioning" }
  summary: { zh: "卡片简介", en: "Card summary" }
  description: { zh: "详情介绍", en: "Detail description" }
  logo: "/assets/apps/Z2Y-Example/logo.png"
  accent: "#e8b86d"
  platforms: ["macOS"]
  price: { zh: "免费", en: "Free" }
  status: "available" # available | preview | in-development
  featured: true
  version: "1.0.0"
  version_label: { zh: "App Store 当前版本", en: "Current App Store version" }
  released_at: "2026-10-01"
  updated_at: "2026-10-12"
  min_os: { zh: "macOS 13.0 或更高版本", en: "macOS 13.0 or later" }
  links:
    primary: "https://example.com/download"
    primary_label: { zh: "下载", en: "Download" }
    source: "https://github.com/zero2you4tech/example"
    product: "https://example.zero2you.tech/"
    support: "/support/example/"
  highlights:
    - { zh: "中文能力", en: "English capability" }
  requirements:
    - { zh: "中文系统要求", en: "English requirement" }
  install:
    - { zh: "中文安装步骤", en: "English installation step" }
  faq:
    - q: { zh: "问题", en: "Question" }
      a: { zh: "回答", en: "Answer" }
  changelog:
    - version: "1.0.0"
      date: "2026-10-12"
      notes: { zh: "中文说明", en: "English note" }
```

`id` must match `_apps/<id>.md`. `order` controls catalog order. Empty `version`, `released_at`, and `updated_at` are allowed for preview or in-development products.

## Release post

```yaml
---
layout: single
title: "中文标题"
title_en: "English title"
date: 2026-10-12 18:00:00 +0800
categories:
  - app-update
app_id: "z2y-example"
version: "1.0.0"
excerpt: "中文摘要"
excerpt_en: "English summary"
author_profile: false
share: false
related: false
---
```

The body should contain separate `data-lang="zh"` and `data-lang="en"` blocks.

## Journal post

Use the same bilingual rules with `categories: [article]`. Journal posts appear on `/journal/`; release posts appear on `/updates/` and on the matching app detail page.

## Source-of-truth rules

- Update `updated_at` only when a version or user-visible change is actually shipped.
- Use `released_at` for the first public release.
- App Store versions come from Apple's lookup response.
- GitHub versions come from the latest published release; do not use a branch or an unmerged commit as a release version.
- If a link is unavailable, omit that link rather than fabricating one.
