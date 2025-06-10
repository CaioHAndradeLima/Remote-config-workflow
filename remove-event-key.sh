#!/bin/bash

# Usage: ./remove-event-key.sh <config_file> <param_name> <string_to_remove>

CONFIG_FILE=$1
PARAM_KEY=$2
STRING_TO_REMOVE=$3

if [[ -z "$CONFIG_FILE" || -z "$PARAM_KEY" || -z "$STRING_TO_REMOVE" ]]; then
  echo "❌ Usage: $0 <config_file> <param_key> <string_to_remove>"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ File not found: $CONFIG_FILE"
  exit 1
fi

# Extract the escaped JSON string from defaultValue
PARAM_JSON_STRING=$(jq -r ".parameters[\"$PARAM_KEY\"].defaultValue.value" "$CONFIG_FILE")

if [[ "$PARAM_JSON_STRING" == "null" ]]; then
  echo "❌ Parameter \"$PARAM_KEY\" not found or has no default value."
  exit 1
fi

# Decode the JSON string
INNER_JSON=$(echo "$PARAM_JSON_STRING" | jq -R 'fromjson')

# Check if the string exists
STRING_INDEX=$(echo "$INNER_JSON" | jq --arg str "$STRING_TO_REMOVE" '.information | index($str)')

if [[ "$STRING_INDEX" == "null" ]]; then
  echo "⚠️  The string \"$STRING_TO_REMOVE\" does not exist in \"$PARAM_KEY\"."
  exit 0
fi

# Remove the string from the list
UPDATED_LIST=$(echo "$INNER_JSON" | jq --arg str "$STRING_TO_REMOVE" '.information | map(select(. != $str))')

# Decrement version only if list is modified
OLD_VERSION=$(echo "$INNER_JSON" | jq '.version')
NEW_VERSION=$((OLD_VERSION - 1))
if [[ "$NEW_VERSION" -lt 0 ]]; then
  NEW_VERSION=0
fi

# Build the updated object
UPDATED_VALUE=$(jq -n \
  --argjson info "$UPDATED_LIST" \
  --argjson version "$NEW_VERSION" \
  '{version: $version, information: $info}' | jq -c .)

# Save updated config
jq --arg val "$UPDATED_VALUE" \
  ".parameters[\"$PARAM_KEY\"].defaultValue.value = \$val" \
  "$CONFIG_FILE" > "updated_$CONFIG_FILE"