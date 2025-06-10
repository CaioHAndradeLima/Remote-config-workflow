#!/bin/bash

PROJECT_ID=$1
ACCESS_TOKEN=$2
OUT_FILE=$3  # New: file to save the JSON

if [[ -z "$ACCESS_TOKEN" || -z "$PROJECT_ID" || -z "$OUT_FILE" ]]; then
  echo "Usage: $0 <project_id> <access_token> <output_file>"
  exit 1
fi

# Create temp file for headers
HEADERS=$(mktemp)

# Requesting remote config
curl -s --compressed \
  -D "$HEADERS" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept-Encoding: gzip" \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -o "$OUT_FILE"

# Extract etag from headers
ETAG=$(grep -i '^etag:' "$HEADERS" | awk -F': ' '{print $2}' | tr -d '\r')

# Inject etag into the saved JSON
TMP=$(mktemp)
jq --arg etag "$ETAG" '. + {etag: $etag}' "$OUT_FILE" > "$TMP" && mv "$TMP" "$OUT_FILE"

# Clean up
rm -f "$HEADERS"
