#!/bin/bash

echo "🔍 Configuration de l'endpoint AWS pour GitHub Codespaces..."

# Vérifier qu'on est bien dans un Codespace
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ ERREUR: Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"
    echo ""
    echo "Pour utiliser ce projet :"
    echo "  1. Ouvrez https://github.com/yilyil/API_Driven"
    echo "  2. Cliquez sur 'Code' > 'Codespaces'"
    echo "  3. Créez un nouveau Codespace"
    exit 1
fi

# Construction de l'URL Codespace
CODESPACE_PORT_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

echo "✓ GitHub Codespace détecté"
echo "✓ Codespace: $CODESPACE_NAME"
echo "✓ URL: $CODESPACE_PORT_URL"

# Sauvegarder l'endpoint
echo "$CODESPACE_PORT_URL" > .aws_endpoint

# Configurer les variables d'environnement
export AWS_ENDPOINT="$CODESPACE_PORT_URL"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "✅ Endpoint configuré: $AWS_ENDPOINT"

# Sauvegarder dans un fichier source
cat > .env << ENVFILE
export AWS_ENDPOINT="$AWS_ENDPOINT"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
ENVFILE

echo "✅ Fichier .env créé"
echo ""
echo "⚠️  ACTION REQUISE :"
echo "    Rendez le port 4566 PUBLIC dans l'onglet PORTS de Codespaces"
echo "    (Clic droit sur port 4566 > Port Visibility > Public)"
