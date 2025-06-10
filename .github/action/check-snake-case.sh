#!/bin/bash

# Function to check if a string is snake_case
is_snake_case() {
  [[ "$1" =~ ^[a-z0-9]+(_[a-z0-9]+)*$ ]]
}

# Function to check if a list of strings is snake_case
is_list_snake_case() {
  local json_array="$1"
  local all_valid=true
  local items=()

  # Read each item using jq and a while-loop
  while IFS= read -r item; do
    items+=("$item")
  done < <(echo "$json_array" | jq -r '.[]')

  for item in "${items[@]}"; do
    if ! is_snake_case "$item"; then
      all_valid=false
      break
    fi
  done

  if $all_valid; then
    return 0
  else
    return 1
  fi
}
