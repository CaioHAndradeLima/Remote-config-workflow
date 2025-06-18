#!/bin/bash

# Uso:
# ./check-json-integrity.sh <parameter_updated> <json_original> <json_updated> <optional: condition>

KEY_TO_IGNORE="$1"
ORIGINAL_JSON="$2"
UPDATED_JSON="$3"
CONDITION_TO_IGNORE="$4"

if [[ -z "$KEY_TO_IGNORE" || -z "$ORIGINAL_JSON" || -z "$UPDATED_JSON" ]]; then
  echo "❌ use: $0 <parameter_updated> <json_original> <json_updated> <optional: condition>"
  exit 1
fi

TMP_ORIGINAL="__tmp_original.json"
TMP_UPDATED="__tmp_updated.json"

# remove the parameter from the two files
jq "del(.parameters[\"$KEY_TO_IGNORE\"])" "$ORIGINAL_JSON" > "$TMP_ORIGINAL"
jq "del(.parameters[\"$KEY_TO_IGNORE\"])" "$UPDATED_JSON" > "$TMP_UPDATED"

# if we passed the condition parameter, we will remove
if [[ -n "$CONDITION_TO_IGNORE" ]]; then
  jq ".conditions |= map(select(.name != \"$CONDITION_TO_IGNORE\"))" "$TMP_ORIGINAL" > "${TMP_ORIGINAL}.tmp" && mv "${TMP_ORIGINAL}.tmp" "$TMP_ORIGINAL"
  jq ".conditions |= map(select(.name != \"$CONDITION_TO_IGNORE\"))" "$TMP_UPDATED" > "${TMP_UPDATED}.tmp" && mv "${TMP_UPDATED}.tmp" "$TMP_UPDATED"
fi

cat "$TMP_ORIGINAL"
cat "$TMP_UPDATED"
# compare the files
if diff -q "$TMP_ORIGINAL" "$TMP_UPDATED" > /dev/null; then
  #echo "✅ no changes found."
  rm -f "$TMP_ORIGINAL" "$TMP_UPDATED"
  exit 0
else
  echo "❌ we found unexpected changes"
  echo "📄 diffs:"
  diff "$TMP_ORIGINAL" "$TMP_UPDATED"
  rm -f "$TMP_ORIGINAL" "$TMP_UPDATED"
  exit 2
fi
