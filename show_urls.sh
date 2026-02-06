#!/bin/bash

if [ ! -f .url_status ]; then
    echo "❌ Déployez d'abord avec: make deploy"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🔗 URLS DE CONTRÔLE EC2                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "▶️  START  : $(cat .url_start)"
echo ""
echo "⏹️  STOP   : $(cat .url_stop)"
echo ""
echo "ℹ️  STATUS : $(cat .url_status)"
echo ""
echo "💡 Copiez-collez ces URLs dans votre navigateur !"
echo ""
