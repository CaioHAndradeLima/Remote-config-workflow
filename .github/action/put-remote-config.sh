#!/bin/bash

# put_remote_config.sh

ACCESS_TOKEN="$1"
PROJECT_ID=horariocomigo
ETAG="$3"
CONFIG_FILE="$4"

if [[ -z "$ACCESS_TOKEN" || -z "$PROJECT_ID" || -z "$ETAG" || -z "$CONFIG_FILE" ]]; then
  echo "use: $0 <access_token> <project_id> <etag> <config_file>"
  exit 1
fi

curl -s -X PUT "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; UTF-8" \
  -H "If-Match: $ETAG" \
  --data-binary @"$CONFIG_FILE" | jq

  # 🧹 Clean up temporary files
  rm -f headers.txt config.json new_config.json
