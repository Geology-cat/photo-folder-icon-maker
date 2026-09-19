#!/bin/bash
#
# 写真フォルダ作成 — ビルドスクリプト
#
# src/ の AppleScript ソースから macOS のドロップレットアプリを生成し、
# 配布用の zip を dist/ に出力する。
#
# 使い方:
#   ./scripts/build.sh            # ビルドのみ
#   ./scripts/build.sh --zip      # ビルド後に配布用 zip も作成
#
set -euo pipefail

VERSION="${VERSION:-1.0.0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/src"
DIST_DIR="$REPO_ROOT/dist"

MAIN_APP="写真フォルダ作成.app"
DESKTOP_APP="写真フォルダ作成_デスクトップ固定.app"

MAKE_ZIP=false
if [[ "${1:-}" == "--zip" ]]; then
  MAKE_ZIP=true
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> ビルド中: $MAIN_APP"
osacompile -o "$DIST_DIR/$MAIN_APP" "$SRC_DIR/PhotoFolderMaker.applescript"

echo "==> ビルド中: $DESKTOP_APP"
osacompile -o "$DIST_DIR/$DESKTOP_APP" "$SRC_DIR/PhotoFolderMaker-Desktop.applescript"

# osacompile が生成するアプリは未署名のため、ad-hoc 署名を付与しておく。
# （Apple Developer ID 署名ではないので、配布時の Gatekeeper 警告は消えない。
#   README の「ダウンロードしたアプリが開けないとき」を参照）
echo "==> ad-hoc 署名を付与"
codesign --force --deep --sign - "$DIST_DIR/$MAIN_APP"
codesign --force --deep --sign - "$DIST_DIR/$DESKTOP_APP"

if [[ "$MAKE_ZIP" == true ]]; then
  ZIP_NAME="PhotoFolderMaker-${VERSION}-macOS.zip"
  echo "==> 配布用 zip を作成: $ZIP_NAME"
  # ditto を使うと、アプリバンドルの拡張属性と署名を保ったまま圧縮できる。
  # --sequesterRsrc は付けない（__MACOSX という不要なエントリが混入するため）
  ditto -c -k --keepParent "$DIST_DIR/$MAIN_APP" "$DIST_DIR/$ZIP_NAME"
fi

echo
echo "完了: $DIST_DIR"
ls -1 "$DIST_DIR"
