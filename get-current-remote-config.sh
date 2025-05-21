#!/bin/bash

ACCESS_TOKEN=$1
PROJECT_ID="horariocomigo"

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "you should pass the token as first parameter: $0 <access_token>"
  exit 1
fi

# Create temp files
RESPONSE=$(mktemp)
HEADERS=$(mktemp)

#requesting remote config
curl -s --compressed \
  -D "$HEADERS" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept-Encoding: gzip" \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -o "$RESPONSE"

#extract etag from header
ETAG=$(grep -i '^etag:' "$HEADERS" | awk -F': ' '{print $2}' | tr -d '\r')

#add etag as a new item into json
jq --arg etag "$ETAG" '. + {etag: $etag}' "$RESPONSE"

#cleaning temp files
rm -f "$RESPONSE" "$HEADERS"