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
STRING_INDEX=$(echo "$INNER_JSON" | jq --arg str "$STRING_TO_REMOVE" '.allowed_event_keys | index($str)')

if [[ "$STRING_INDEX" == "null" ]]; then
  echo "⚠️  The string \"$STRING_TO_REMOVE\" does not exist in the parameter \"$PARAM_KEY\"."
  exit 1
fi

# Remove the string from list
UPDATED_INNER_JSON=$(echo "$INNER_JSON" | jq --arg str "$STRING_TO_REMOVE" '
  .allowed_event_keys -= [$str]
')

# Re-escape updated value
UPDATED_VALUE=$(echo "$UPDATED_INNER_JSON" | jq -c .)

# Replace value in original config and save as new file
jq --arg val "$UPDATED_VALUE" ".parameters[\"$PARAM_KEY\"].defaultValue.value = \$val" "$CONFIG_FILE" > "updated_$CONFIG_FILE"
