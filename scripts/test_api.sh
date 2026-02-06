#!/bin/bash

# Charger les variables d'environnement
if [ -f .env ]; then
    source .env
fi

INSTANCE_ID=$(cat .instance_id 2>/dev/null)
API_URL=$(cat .api_url 2>/dev/null)

if [ -z "$INSTANCE_ID" ] || [ -z "$API_URL" ]; then
    echo "❌ Configuration manquante. Exécutez 'make deploy' d'abord."
    exit 1
fi

echo "🧪 Test de l'API EC2 Controller"
echo "================================"
echo "📍 Endpoint: $AWS_ENDPOINT"
echo "🆔 Instance: $INSTANCE_ID"
echo "🔗 API URL: $API_URL"
echo ""

echo "1️⃣  Test: Vérification du statut"
curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"action\": \"status\", \"instance_id\": \"$INSTANCE_ID\"}" \
    --insecure \
    | jq '.'

echo ""
echo "2️⃣  Test: Arrêt de l'instance"
curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"action\": \"stop\", \"instance_id\": \"$INSTANCE_ID\"}" \
    --insecure \
    | jq '.'

sleep 3

echo ""
echo "3️⃣  Test: Vérification après arrêt"
curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"action\": \"status\", \"instance_id\": \"$INSTANCE_ID\"}" \
    --insecure \
    | jq '.'

echo ""
echo "4️⃣  Test: Redémarrage de l'instance"
curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"action\": \"start\", \"instance_id\": \"$INSTANCE_ID\"}" \
    --insecure \
    | jq '.'

echo ""
echo "✅ Tests terminés"
