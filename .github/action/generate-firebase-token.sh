#!/bin/bash

CLIENT_EMAIL="$1"
PRIVATE_KEY="$2"

# JWT header
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# JWT claim set
NOW=$(date +%s)
EXP=$((NOW + 3600))
SCOPE="https://www.googleapis.com/auth/firebase.remoteconfig"
AUD="https://oauth2.googleapis.com/token"
CLAIM=$(echo -n "{\"iss\":\"$CLIENT_EMAIL\",\"scope\":\"$SCOPE\",\"aud\":\"$AUD\",\"iat\":$NOW,\"exp\":$EXP}" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Combine header and claim
JWT_UNSIGNED="$HEADER.$CLAIM"

# Sign it using openssl and the private key
SIGNATURE=$(echo -n "$JWT_UNSIGNED" | \
  openssl dgst -sha256 -sign <(echo -e "$PRIVATE_KEY") | \
  openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Final JWT
JWT="$JWT_UNSIGNED.$SIGNATURE"

# Exchange for access token
curl -s -X POST https://oauth2.googleapis.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  -d "assertion=$JWT" | jq
