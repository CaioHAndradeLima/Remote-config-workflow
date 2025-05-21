#!/bin/bash

TOKEN_JSON=$(./get-token.sh)

ACCESS_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.access_token')

echo "Token: $ACCESS_TOKEN"
