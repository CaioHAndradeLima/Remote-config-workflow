#!/bin/bash

# Load the functions
source ./check-snake-case.sh

# Check single string
if is_snake_case "$1"; then
  echo "✅ '$1' is snake_case"
else
  echo "❌ '$1' is NOT snake_case"
fi
