#!/bin/bash

# Path to your service account JSON
KEY_FILE="service-account.json"

# Read values from JSON
CLIENT_EMAIL=$(jq -r '.client_email' "$KEY_FILE")
PRIVATE_KEY=$(jq -r '.private_key' "$KEY_FILE" | sed 's/\\n/\n/g')

./generate-firebase-token.sh $CLIENT_EMAIL "$PRIVATE_KEY"