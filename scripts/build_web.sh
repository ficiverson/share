#!/usr/bin/env bash
# build_web.sh — Generates firebase-messaging-sw.js from the template and builds the web app.
#
# Usage:
#   ./scripts/build_web.sh \
#     --worker-url  https://share-fcm-sender.<user>.workers.dev/ \
#     --secret      <SHARED_SECRET> \
#     --vapid-key   <VAPID_KEY>
#
# Requires: flutter, firebase_options.dart already generated (run flutterfire configure first).

set -euo pipefail

WORKER_URL=""
SHARED_SECRET=""
VAPID_KEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worker-url) WORKER_URL="$2"; shift 2 ;;
    --secret)     SHARED_SECRET="$2"; shift 2 ;;
    --vapid-key)  VAPID_KEY="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

OPTS_FILE="lib/firebase_options.dart"
if [[ ! -f "$OPTS_FILE" ]]; then
  echo "❌  $OPTS_FILE not found. Run 'flutterfire configure' first."
  exit 1
fi

extract() {
  grep "$1" "$OPTS_FILE" | grep -v android | grep -v ios | grep -v macos | head -1 \
    | sed "s/.*'\\(.*\\)'.*/\\1/"
}

API_KEY=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "apiKey" | sed "s/.*'\\(.*\\)'.*/\\1/")
AUTH_DOMAIN=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "authDomain" | sed "s/.*'\\(.*\\)'.*/\\1/")
PROJECT_ID=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "projectId" | head -1 | sed "s/.*'\\(.*\\)'.*/\\1/")
STORAGE_BUCKET=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "storageBucket" | sed "s/.*'\\(.*\\)'.*/\\1/")
SENDER_ID=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "messagingSenderId" | sed "s/.*'\\(.*\\)'.*/\\1/")
APP_ID=$(grep -A 10 "static const FirebaseOptions web" "$OPTS_FILE" | grep "appId" | head -1 | sed "s/.*'\\(.*\\)'.*/\\1/")

echo "📦  Generating web/firebase-messaging-sw.js..."
sed \
  -e "s|%%FCM_API_KEY%%|$API_KEY|g" \
  -e "s|%%FCM_AUTH_DOMAIN%%|$AUTH_DOMAIN|g" \
  -e "s|%%FCM_PROJECT_ID%%|$PROJECT_ID|g" \
  -e "s|%%FCM_STORAGE_BUCKET%%|$STORAGE_BUCKET|g" \
  -e "s|%%FCM_SENDER_ID%%|$SENDER_ID|g" \
  -e "s|%%FCM_APP_ID%%|$APP_ID|g" \
  web/firebase-messaging-sw.template.js > web/firebase-messaging-sw.js

echo "🔨  Building Flutter web..."
flutter build web --release \
  --dart-define=FCM_WORKER_URL="$WORKER_URL" \
  --dart-define=FCM_SHARED_SECRET="$SHARED_SECRET" \
  --dart-define=FCM_VAPID_KEY="$VAPID_KEY"

echo "✅  Done. Run 'firebase deploy --only hosting' to publish."
