#!/bin/bash

# Usage: ./add-event-key.sh <config_file> <param_name> <new_string>

CONFIG_FILE=$1
PARAM_KEY=$2
NEW_STRING=$3

if [[ -z "$CONFIG_FILE" || -z "$PARAM_KEY" || -z "$NEW_STRING" ]]; then
  echo "❌ Usage: $0 <config_file> <param_key> <new_string>"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ File not found: $CONFIG_FILE"
  exit 1
fi

# Extract the JSON string from defaultValue
PARAM_JSON_STRING=$(jq -r ".parameters[\"$PARAM_KEY\"].defaultValue.value" "$CONFIG_FILE")

if [[ "$PARAM_JSON_STRING" == "null" ]]; then
  echo "❌ Parameter \"$PARAM_KEY\" not found or has no default value."
  exit 1
fi

# Decode the escaped JSON string
INNER_JSON=$(echo "$PARAM_JSON_STRING" | jq -R 'fromjson')

# Check if the string is already present
ALREADY_EXISTS=$(echo "$INNER_JSON" | jq --arg str "$NEW_STRING" '.allowed_event_keys | index($str)')

if [[ "$ALREADY_EXISTS" != "null" ]]; then
  echo "⚠️  The string \"$NEW_STRING\" already exists in the parameter \"$PARAM_KEY\"."
  exit 0
fi

# Add the string to the list and increment version
NEW_LIST=$(echo "$INNER_JSON" | jq --arg str "$NEW_STRING" '.allowed_event_keys + [$str]')
NEW_VERSION=$(echo "$INNER_JSON" | jq '.version + 1')

# Construct updated JSON and escape it
UPDATED_VALUE=$(jq -n \
  --argjson info "$NEW_LIST" \
  --argjson version "$NEW_VERSION" \
  '{version: $version, allowed_event_keys: $info}' | jq -c .)

# Replace value in original config and save as new file
jq --arg val "$UPDATED_VALUE" ".parameters[\"$PARAM_KEY\"].defaultValue.value = \$val" "$CONFIG_FILE" > "updated_$CONFIG_FILE"
