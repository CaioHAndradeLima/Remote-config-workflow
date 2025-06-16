#!/bin/bash

# put_remote_config.sh

ACCESS_TOKEN="$1"
PROJECT_ID="$2"
CONFIG_FILE="$3"

if [[ -z "$ACCESS_TOKEN" || -z "$PROJECT_ID" || -z "$CONFIG_FILE" ]]; then
  echo "use: $0 <access_token> <project_id> <etag> <config_file>"
  exit 1
fi

# Extract ETag from config and remove it from JSON
ETAG=$(jq -r '.etag // empty' "$CONFIG_FILE")
if [[ -z "$ETAG" ]]; then
  echo "❌ ETag not found in config file."
  exit 1
fi

CLEANED_FILE=$(mktemp)
jq 'del(.etag)' "$CONFIG_FILE" > "$CLEANED_FILE"

curl -s -X PUT "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; UTF-8" \
  -H "If-Match: $ETAG" \
  --data-binary @"$CONFIG_FILE" | jq

  # 🧹 Clean up temporary files
rm -f "$CLEANED_FILE"
