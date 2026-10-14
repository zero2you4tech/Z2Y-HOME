# Visual Assets

Every post on the site needs a visual, because the post layout is a two-column shell: a sticky visual panel on the left and the article body on the right. A post without a visual leaves an empty left column.

## Resolution order

`_layouts/single.html` resolves the left-panel visual in this order:

1. `visual` in the post front matter (explicit image path).
2. The first entry of `screenshots` for the post's `app_id` in `_data/apps.yml`.
3. The app logo from `_data/apps.yml`.

So release posts get product imagery for free when the app has screenshots. Journal posts must set `visual` explicitly.

Extra front matter keys:

```yaml
visual: "/assets/.../01-topic.png"
visual_kind: "product"        # or "illustration" / "note" (drives the panel treatment)
visual_caption: "中文图注"
visual_caption_en: "English caption"
```

## Product visuals (release posts)

Use real product imagery, never a generated mockup of a product UI.

- Preferred source: the App Store screenshots already stored under `assets/apps/<App Folder>/`.
- Register them in `_data/apps.yml` under `screenshots` with bilingual captions; the app page, the release-post panel, and the `/updates/` thumbnail all reuse the same entries.
- If an app has no screenshots yet, add them, or leave the `screenshots` key out and the layout falls back to the logo.

Do not paste a screenshot into a post body as the only visual. The left panel is the visual slot.

## Journal visuals (articles)

Use the `ian-xiaohei-illustrations` skill for Chinese article illustrations. Read that skill and its references before drawing.

Preferred path:

- Use the built-in image generation tool when it is available.
- Do not let the absence of that tool block the work: `scripts/xiaohei_sketch.rb` renders a deterministic hand-drawn illustration from a JSON spec when no image-generation tool or API is reachable.

Style contract for this site (do not drift):

- 16:9, pure white background, black hand-drawn line art, lots of white space.
- 小黑 (solid black blob, white dot eyes, thin legs) must perform the core conceptual action.
- At most 5-8 short Chinese handwritten labels: black for structure, orange for flow, red for the key problem, blue for secondary notes.
- One image explains exactly one core structure. Never a formal diagram, never a top-left type title.

Rendering a spec:

```bash
ruby .codex/skills/zero2you-site-manager/scripts/xiaohei_sketch.rb \
  --spec assets/journal/<slug>/spec.json \
  --out assets/journal/<slug>/01-topic.svg \
  --png assets/journal/<slug>/01-topic.png \
  --width 1600
```

Commit the SVG source, the PNG that the site references, and `spec.json` so the illustration stays editable and reproducible.

Before publishing, open the PNG and check it against the 小黑 rules in `references/qa-checklist.md` of the `ian-xiaohei-illustrations` skill: 小黑 central, enough white space, not a flowchart, no top-left title, labels short and spelled correctly. Regenerate rather than ship a bad illustration.

## Daily thought notes

Daily thought cards come from the `aphorism-notebook` skill (`~/Thinking`, "思笺 · Thought Cards"). Use it for 日常思考手记, not for product documentation.

- A thought note is a short aphorism (8-16 characters) plus a 120-900 character journey.
- Publish it on this site as a journal post: `categories: [article]`, with `visual` pointing at an illustration whose metaphor comes from the card's own journey.
- Keep the card itself in the `Thinking` repository; this site only republishes it. Never edit the card's journey here and never invent a card this site's author did not write.
- Front matter should carry `source_url` pointing at the published card so the original is discoverable:

```yaml
source_url: "https://<thinking-site>/cards/<slug>"
```
