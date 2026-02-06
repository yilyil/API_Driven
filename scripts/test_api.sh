#!/bin/bash

if [ ! -f .url_status ]; then
    echo "❌ Exécutez 'make deploy' d'abord"
    exit 1
fi

# Charger les URLs
URL_START=$(cat .url_start)
URL_STOP=$(cat .url_stop)
URL_STATUS=$(cat .url_status)

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                🧪 TESTS DE L'API EC2 CONTROLLER                            ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Test STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URL : $URL_STATUS"
echo ""
curl -s -k "$URL_STATUS" | jq '.' || echo "❌ Erreur"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Test STOP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URL : $URL_STOP"
echo ""
curl -s -k "$URL_STOP" | jq '.' || echo "❌ Erreur"

echo ""
echo "⏳ Attente de 3 secondes..."
sleep 3

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Test STATUS (après STOP)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URL : $URL_STATUS"
echo ""
curl -s -k "$URL_STATUS" | jq '.' || echo "❌ Erreur"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Test START"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URL : $URL_START"
echo ""
curl -s -k "$URL_START" | jq '.' || echo "❌ Erreur"

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                          ✅ TESTS TERMINÉS                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Récapitulatif des URLs :"
echo "   START  : $URL_START"
echo "   STOP   : $URL_STOP"
echo "   STATUS : $URL_STATUS"
echo ""
