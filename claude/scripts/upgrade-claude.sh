#!/bin/bash
# Claude Codeアップグレードスクリプト
# Homebrew CaskでインストールされたClaude Codeを最新版に更新する

set -e

echo "=== Claude Code アップグレード ==="
echo ""

# Homebrewの存在確認
if ! command -v brew &> /dev/null; then
    echo "❌ エラー: Homebrewがインストールされていません"
    exit 1
fi

# 現在のバージョン情報を取得
echo "📋 現在のバージョン情報を確認中..."
echo ""
brew info --cask claude-code 2>/dev/null || {
    echo "❌ エラー: claude-codeがHomebrewでインストールされていません"
    echo "   インストールするには: brew install --cask claude-code"
    exit 1
}

echo ""
echo "🔄 アップグレードを実行中..."
echo ""

# アップグレード実行
if brew upgrade --cask claude-code 2>&1; then
    echo ""
    echo "✅ アップグレード完了"
    echo ""
    echo "📋 新しいバージョン情報:"
    brew info --cask claude-code | head -n 3
else
    # 既に最新の場合
    echo ""
    echo "ℹ️  Claude Codeは既に最新バージョンです"
fi
