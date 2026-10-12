#!/usr/bin/env bash
set -euo pipefail

repo="${Z2Y_HOME_REPO:-$HOME/WorkSpace/Project/Web/zero2you4tech/Z2Y-HOME}"
message=""
remote="origin"
branch="main"
push="false"
dry_run="false"
paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --message) message="$2"; shift 2 ;;
    --remote) remote="$2"; shift 2 ;;
    --branch) branch="$2"; shift 2 ;;
    --push) push="true"; shift ;;
    --dry-run) dry_run="true"; shift ;;
    --) shift; while [[ $# -gt 0 ]]; do paths+=("$1"); shift; done ;;
    *) paths+=("$1"); shift ;;
  esac
done

if [[ -z "$message" ]]; then
  echo "Missing --message" >&2
  exit 1
fi
if [[ ${#paths[@]} -eq 0 ]]; then
  echo "Pass one or more paths to stage after --" >&2
  exit 1
fi
if [[ ! -f "$repo/_data/apps.yml" ]]; then
  echo "Not a Zero2You site repo: $repo" >&2
  exit 1
fi

validator="$repo/.codex/skills/zero2you-site-manager/scripts/validate_site_content.rb"
ruby "$validator" "$repo"

if [[ "$dry_run" == "true" ]]; then
  git -C "$repo" status --short -- "${paths[@]}"
  git -C "$repo" diff -- "${paths[@]}"
  echo "Dry run complete. No files were staged, committed, or pushed."
  exit 0
fi

git -C "$repo" add -- "${paths[@]}"
if git -C "$repo" diff --cached --quiet; then
  echo "No staged changes for the supplied paths."
  exit 0
fi

git -C "$repo" commit -m "$message"
if [[ "$push" != "true" ]]; then
  echo "Committed locally. Re-run with --push to publish through GitHub Pages."
  exit 0
fi

git -C "$repo" push "$remote" "$branch"
echo "Pushed $branch to $remote."

if command -v gh >/dev/null 2>&1; then
  gh run list --repo zero2you4tech/Z2Y-HOME --workflow "Deploy Jekyll site to Pages" --limit 1 || true
fi
