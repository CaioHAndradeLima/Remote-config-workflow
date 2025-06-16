#!/bin/bash

ACCESS_TOKEN=$1
NEW_STRING=$2
PROJECT_ID="horariocomigo"
PARAM_NAME="parametro1"

if [[ -z "$ACCESS_TOKEN" || -z "$NEW_STRING" ]]; then
  echo "Uso: $0 <access_token> <nova_string>"
  exit 1
fi

echo "📥 Baixando Remote Config..."

# Faz a requisição completa com headers + body, salvando headers em um arquivo temporário
curl -s --compressed \
  -D headers.txt \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept-Encoding: gzip" \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -o config.json

# Extrai o ETag do arquivo de headers
ETAG=$(grep -i '^etag:' headers.txt | awk -F': ' '{print $2}' | tr -d '\r')

# Exibe o ETag extraído
echo "🔖 ETag extraído: $ETAG"

# Verifica se o parâmetro existe
PARAM_VALUE=$(jq -r ".parameters.\"$PARAM_NAME\".defaultValue.value" config.json)
echo "🔍 PARAM_VALUE original (string JSON escapada):"
echo "$PARAM_VALUE"

if [[ "$PARAM_VALUE" == "null" ]]; then
  echo "❌ Parâmetro \"$PARAM_NAME\" não encontrado no Remote Config."
  exit 1
fi

# Corrige o parse do JSON aninhado
INNER_JSON=$(echo "$PARAM_VALUE" | jq -rR 'fromjson')
echo "🧩 INNER_JSON desescapado:"
echo "$INNER_JSON" | jq .

# Extrai versão e lista
OLD_VERSION=$(echo "$INNER_JSON" | jq -r '.version')
OLD_LIST=$(echo "$INNER_JSON" | jq '.allowed_event_keys')

echo "📦 Versão antiga: $OLD_VERSION"
echo "📚 Lista antiga:"
echo "$OLD_LIST"

# Adiciona nova string à lista
NEW_LIST=$(echo "$OLD_LIST" | jq --arg new "$NEW_STRING" '. + [$new]')
echo "🆕 Lista nova:"
echo "$NEW_LIST"

NEW_VERSION=$((OLD_VERSION + 1))
echo "🧮 Nova versão: $NEW_VERSION"

# Cria o novo valor JSON (como string JSON escapada)
NEW_VALUE_ESCAPED=$(jq -n \
  --argjson info "$NEW_LIST" \
  --argjson version "$NEW_VERSION" \
  '{version: $version, allowed_event_keys: $info}' | jq -c .)

echo "🧪 Novo valor JSON (pronto para ser salvo como string):"
echo "$NEW_VALUE_ESCAPED"

# Atualiza config.json com novo valor
jq --arg val "$NEW_VALUE_ESCAPED" \
  ".parameters.\"$PARAM_NAME\".defaultValue.value = \$val" config.json > new_config.json

echo "📤 Novo config.json gerado:"
cat new_config.json | jq .

# Faz upload
echo "🚀 Atualizando Remote Config com nova string e versão $NEW_VERSION..."


curl -s -X PUT "https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT_ID/remoteConfig" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; UTF-8" \
  -H "If-Match: $ETAG" \
  --data-binary @new_config.json | jq

echo "✅ Atualização concluída."

# 🧹 Clean up temporary files
#rm -f headers.txt config.json new_config.json
