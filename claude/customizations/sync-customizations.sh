#!/usr/bin/env bash
# sync-customizations.sh — dotfiles 管理のカスタマイズを marketplace/cache に反映
#
# プラグイン更新後に実行して、カスタマイズを再適用する。
# Usage: bash claude/customizations/sync-customizations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE_DIR="$(dirname "$SCRIPT_DIR")/plugins/marketplaces/claude-code-harness-marketplace"
CACHE_BASE="$(dirname "$SCRIPT_DIR")/plugins/cache/claude-code-harness-marketplace/claude-code-harness"

echo "🔄 Harness カスタマイズを同期中..."

# 1. config を同期
if [[ -f "$SCRIPT_DIR/.claude-code-harness.config.yaml" ]]; then
  cp "$SCRIPT_DIR/.claude-code-harness.config.yaml" "$MARKETPLACE_DIR/.claude-code-harness.config.yaml"
  echo "  ✓ .claude-code-harness.config.yaml → marketplace"

  # cache の全バージョンにも反映
  for ver_dir in "$CACHE_BASE"/*/; do
    if [[ -d "$ver_dir" ]]; then
      cp "$SCRIPT_DIR/.claude-code-harness.config.yaml" "$ver_dir/.claude-code-harness.config.yaml"
      echo "  ✓ .claude-code-harness.config.yaml → cache/$(basename "$ver_dir")"
    fi
  done
fi

# 2. harness-review SKILL.md を同期
if [[ -f "$SCRIPT_DIR/harness-review/SKILL.md" ]]; then
  mkdir -p "$MARKETPLACE_DIR/skills/harness-review"
  cp "$SCRIPT_DIR/harness-review/SKILL.md" "$MARKETPLACE_DIR/skills/harness-review/SKILL.md"
  echo "  ✓ harness-review/SKILL.md → marketplace"

  for ver_dir in "$CACHE_BASE"/*/; do
    if [[ -d "$ver_dir/skills/harness-review" ]]; then
      cp "$SCRIPT_DIR/harness-review/SKILL.md" "$ver_dir/skills/harness-review/SKILL.md"
      echo "  ✓ harness-review/SKILL.md → cache/$(basename "$ver_dir")"
    fi
  done
fi

echo "✅ カスタマイズ同期完了"
