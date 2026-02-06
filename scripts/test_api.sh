#!/bin/bash

# Charger l'environnement
source .env 2>/dev/null || { echo "❌ Erreur: Fichier .env manquant"; exit 1; }
API_ID=$(cat .api_id 2>/dev/null)
API_URL="${AWS_ENDPOINT}/restapis/${API_ID}/prod/_user_request_/ec2"

echo "🧪 Test de l'API API-Driven..."
echo "🔗 URL: $API_URL"
echo "------------------------------------"

function call_api() {
    local action=$1
    echo "▶️  Action: $action"
    
    # Appel curl avec -k (insecure) et silence pour les warnings urllib3
    response=$(curl -s -k -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"action\": \"$action\"}")
    
    echo "📩 Réponse: $response"
    echo ""
}

# Séquence de tests
call_api "status"
sleep 2
call_api "stop"
sleep 5
call_api "status"
sleep 2
call_api "start"

echo "✅ Tests terminés !"
