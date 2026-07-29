#!/usr/bin/env bash
# Capture real product screenshots from the seeded demo wedding into
# app/assets/images/marketing/. Requires: local server, Playwright, ImageMagick.
#
#   bin/rails runner 'Seeds::DemoWedding.call'
#   bin/rails server -p 3003
#   script/capture_marketing_screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${TMPDIR:-/tmp}/vowd-pw-shots"
mkdir -p "$WORK"
cd "$WORK"

if [[ ! -d node_modules/playwright ]]; then
  npm init -y >/dev/null 2>&1
  npm install playwright@1.58.0 >/dev/null 2>&1
  npx playwright install chromium >/dev/null 2>&1
fi

cp "$ROOT/script/capture_marketing_screenshots.js" ./capture.js
APP_BASE_DOMAIN="${APP_BASE_DOMAIN:-vowd.localhost}" APP_PORT="${APP_PORT:-3003}" node capture.js
