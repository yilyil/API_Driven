#!/bin/bash

# Charger les variables d'environnement
if [ -f .env ]; then
    source .env
fi

ACTION=$1
INSTANCE_ID=$(cat .instance_id 2>/dev/null)
API_URL=$(cat .api_url 2>/dev/null)

if [ -z "$INSTANCE_ID" ] || [ -z "$API_URL" ]; then
    echo "❌ Configuration manquante. Exécutez 'make deploy' d'abord."
    exit 1
fi

echo "🔄 Action: $ACTION"
echo "📍 Endpoint: $AWS_ENDPOINT"
echo ""

curl -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"action\": \"$ACTION\", \"instance_id\": \"$INSTANCE_ID\"}" \
    --insecure \
    | jq '.'
