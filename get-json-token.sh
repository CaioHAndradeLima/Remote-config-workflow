#!/bin/bash

TOKEN_JSON=$(./get-token.sh)

ACCESS_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.access_token')

REMOTE_CONFIG_JSON=$(./get-current-remote-config.sh $ACCESS_TOKEN)

