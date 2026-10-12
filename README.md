# Zero2You Studio Home

工作室门户网站： https://www.zero2you.tech/

## 内容结构

- `_data/apps.yml`：全部 App 的资料源，包含中英双语介绍、版本、平台、价格、安装说明、FAQ 和版本记录。
- `_apps/*.md`：App 详情页入口。页面由 `_data/apps.yml` 渲染，不在这里重复维护业务信息。
- `_posts/*`：产品动态与工作室手记。
  - `categories: [app-update]`：产品版本更新，会出现在首页和 `/updates/`。
  - `categories: [article]`：工作室文章，会出现在 `/journal/`。
- `_data/ui.yml`：中英文界面文案。
- `assets/css/z2y.css`、`assets/js/z2y.js`：站点视觉系统与语言、筛选、搜索交互。

## 更新 App 信息

优先使用随仓库提供的 Codex Skill：

```bash
.codex/skills/zero2you-site-manager/scripts/upsert_app.rb \
  --app z2y-ai \
  --patch /tmp/z2y-ai-patch.json \
  --create-page
```

发布新版本动态：

```bash
.codex/skills/zero2you-site-manager/scripts/create_release_post.rb \
  --app z2y-ai \
  --version 1.2.0 \
  --date 2026-10-12 \
  --title "Z2Y AI Manager 更新至 1.2.0" \
  --title-en "Z2Y AI Manager reaches 1.2.0" \
  --summary-zh "更新摘要" \
  --summary-en "Release summary"
```

提交并推送后，`.github/workflows/jekyll.yml` 会校验内容、构建 Jekyll，并部署到 GitHub Pages：

```bash
.codex/skills/zero2you-site-manager/scripts/publish_site.sh \
  --message "Update Z2Y AI Manager 1.2.0" \
  --push \
  _data/apps.yml _apps/z2y-ai.md _posts/2026-10-12-z2y-ai-1-2-0.md
```

## 本地预览

```bash
bundle install --path vendor/bundle
bundle exec jekyll serve
```

如果本机 Ruby/Gem 环境无法安装 GitHub Pages 依赖，可以直接依赖 GitHub Actions 构建，或使用已安装的 Jekyll 环境运行 `jekyll build`。
