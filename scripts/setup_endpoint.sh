#!/bin/bash

echo "🔍 Configuration de l'endpoint AWS pour GitHub Codespaces..."

# Vérifier qu'on est bien dans un Codespace
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ ERREUR: Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"
    exit 1
fi

echo "✓ GitHub Codespace détecté: $CODESPACE_NAME"

# Rendre le port 4566 public automatiquement avec gh CLI
echo ""
echo "🔓 Configuration automatique du port 4566 en PUBLIC..."

# Utiliser gh pour rendre le port public
gh codespace ports visibility 4566:public -c $CODESPACE_NAME 2>/dev/null || \
    echo "⚠️  Impossible de rendre le port public automatiquement. Faites-le manuellement."

sleep 2

# Construction de l'URL Codespace
CODESPACE_PORT_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

echo "✓ URL configurée: $CODESPACE_PORT_URL"

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
echo "⏳ Attente de 5 secondes pour que le port devienne accessible..."
sleep 5
