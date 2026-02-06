#!/bin/bash

echo "🔍 Configuration de l'endpoint AWS..."

# Récupérer l'URL publique du port 4566 depuis GitHub Codespaces
if [ -n "$CODESPACE_NAME" ]; then
    # On est dans un Codespace
    CODESPACE_PORT_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    echo "✓ Codespace détecté"
    echo "✓ URL: $CODESPACE_PORT_URL"
    
    # Sauvegarder l'endpoint
    echo "$CODESPACE_PORT_URL" > .aws_endpoint
    
    # Configurer les variables d'environnement
    export AWS_ENDPOINT="$CODESPACE_PORT_URL"
else
    # Environnement local
    echo "✓ Environnement local détecté"
    export AWS_ENDPOINT="http://localhost:4566"
    echo "$AWS_ENDPOINT" > .aws_endpoint
fi

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

echo "✅ Endpoint configuré: $AWS_ENDPOINT"

# Sauvegarder dans un fichier source pour les autres scripts
cat > .env << ENVFILE
export AWS_ENDPOINT="$AWS_ENDPOINT"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
ENVFILE

echo "✅ Fichier .env créé"
