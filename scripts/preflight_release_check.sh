#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[1/4] Checking git worktree"
git status --short

echo "[2/4] Checking build-profile.json5 is sanitized"
if rg -n '/Users/.+\\.ohos/config|keyPassword\\s*:\\s*\"0000|storePassword\\s*:\\s*\"0000' build-profile.json5 >/dev/null 2>&1; then
  echo "ERROR: build-profile.json5 contains real signing paths or secrets"
  exit 1
fi

if ! rg -n 'REPLACE_WITH_LOCAL_SECRET|YOUR_RELEASE_CERT|YOUR_RELEASE_PROFILE|YOUR_RELEASE_KEYSTORE|YOUR_KEY_ALIAS' build-profile.json5 >/dev/null 2>&1; then
  echo "WARNING: build-profile.json5 does not look like the sanitized template"
fi

echo "[3/4] Checking tracked generated files"
TRACKED_GENERATED="$(git ls-files | rg '^(.hvigor/|.idea/|entry/build/|local\\.properties$)' || true)"
if [[ -n "$TRACKED_GENERATED" ]]; then
  echo "ERROR: generated/local files are tracked:"
  echo "$TRACKED_GENERATED"
  exit 1
fi

echo "[4/4] Checking release docs"
for file in \
  docs/appgallery/APPGALLERY_SUBMISSION_CHECKLIST.md \
  docs/appgallery/APPGALLERY_CONNECT_STEPS.md \
  docs/appgallery/DEVICE_TEST_PLAN.md \
  docs/appgallery/PRIVACY_POLICY_zh-CN.md \
  docs/appgallery/RELEASE_BUILD_AND_SIGN.md \
  docs/appgallery/RELEASE_LOG.md \
  docs/appgallery/STORE_METADATA_zh-CN.md \
  docs/appgallery/LOCAL_SIGNING_SETUP.md \
  docs/appgallery/SIGNING_ROTATION_SOP.md
do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing required file $file"
    exit 1
  fi
done

echo "Preflight check passed."
