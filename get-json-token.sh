#!/bin/bash

TOKEN_JSON=$(.generate-firebase-token.sh)

ACCESS_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.access_token')

REMOTE_CONFIG_JSON=$(.firebase-get-request.sh $ACCESS_TOKEN)

