#!/bin/bash
set -e

echo "🚀 Déploiement de l'infrastructure API-Driven (GitHub Codespaces)"

# Vérifier qu'on est dans Codespaces
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ ERREUR: Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"
    exit 1
fi

# Charger les variables d'environnement
if [ -f .env ]; then
    source .env
    echo "✓ Variables d'environnement chargées"
else
    echo "❌ Fichier .env manquant"
    exit 1
fi

echo "📍 Endpoint AWS: $AWS_ENDPOINT"

# Test de connexion
echo ""
echo "🔌 Test de connexion à LocalStack..."
HEALTH_CHECK=$(curl -s -k "$AWS_ENDPOINT/_localstack/health" 2>/dev/null || echo "")

if [ -z "$HEALTH_CHECK" ]; then
    echo "❌ Impossible de se connecter à LocalStack"
    echo ""
    echo "Solutions possibles:"
    echo "  1. Vérifiez que LocalStack est démarré: make setup"
    echo "  2. Le port 4566 doit être PUBLIC"
    echo "  3. Testez manuellement: curl -k $AWS_ENDPOINT/_localstack/health"
    exit 1
fi

echo "✓ Connexion à LocalStack OK"

# 1. Création de l'instance EC2
echo ""
echo "📦 Création de l'instance EC2..."

# Supprimer l'ancienne clé
rm -f my-key.pem

# Créer Key Pair
awslocal ec2 create-key-pair \
    --key-name my-key \
    --query 'KeyMaterial' \
    --output text > my-key.pem 2>/dev/null || echo "✓ Key pair existe"
chmod 400 my-key.pem 2>/dev/null

# Créer Security Group
awslocal ec2 create-security-group \
    --group-name my-sg \
    --description "Security group" 2>/dev/null || echo "✓ Security group existe"

# Vérifier instance existante
EXISTING_INSTANCE=$(awslocal ec2 describe-instances \
    --filters "Name=tag:Name,Values=API-Driven-Instance" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

if [ "$EXISTING_INSTANCE" != "None" ] && [ -n "$EXISTING_INSTANCE" ] && [ "$EXISTING_INSTANCE" != "null" ]; then
    export INSTANCE_ID="$EXISTING_INSTANCE"
    echo "✓ Instance existante: $INSTANCE_ID"
else
    echo "→ Création d'une nouvelle instance..."
    awslocal ec2 run-instances \
        --image-id ami-ff0fea8310f3 \
        --count 1 \
        --instance-type t2.micro \
        --key-name my-key \
        --security-groups my-sg \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=API-Driven-Instance}]' > /dev/null
    
    sleep 2
    
    export INSTANCE_ID=$(awslocal ec2 describe-instances \
        --filters "Name=tag:Name,Values=API-Driven-Instance" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
fi

echo "✓ Instance ID: $INSTANCE_ID"
echo "$INSTANCE_ID" > .instance_id

# 2. Fonction Lambda
echo ""
echo "⚡ Création de la fonction Lambda..."
cd lambda
rm -f lambda_function.zip
zip -q lambda_function.zip lambda_function.py

# Créer rôle IAM
awslocal iam create-role \
    --role-name lambda-ec2-role \
    --assume-role-policy-document file://../policies/trust-policy.json > /dev/null 2>&1 || true

awslocal iam put-role-policy \
    --role-name lambda-ec2-role \
    --policy-name EC2Access \
    --policy-document file://../policies/ec2-policy.json > /dev/null

# Créer/mettre à jour Lambda
if awslocal lambda get-function --function-name ec2-controller &>/dev/null; then
    awslocal lambda update-function-code \
        --function-name ec2-controller \
        --zip-file fileb://lambda_function.zip > /dev/null
    echo "✓ Lambda mise à jour"
else
    awslocal lambda create-function \
        --function-name ec2-controller \
        --runtime python3.9 \
        --role arn:aws:iam::000000000000:role/lambda-ec2-role \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip \
        --environment Variables="{INSTANCE_ID=$INSTANCE_ID,AWS_ENDPOINT=$AWS_ENDPOINT}" \
        --timeout 30 > /dev/null
    echo "✓ Lambda créée"
fi

awslocal lambda update-function-configuration \
    --function-name ec2-controller \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID,AWS_ENDPOINT=$AWS_ENDPOINT}" > /dev/null

cd ..

# 3. API Gateway avec 3 endpoints GET
echo ""
echo "🌐 Création de l'API Gateway..."

# Créer ou récupérer l'API
EXISTING_API=$(awslocal apigateway get-rest-apis \
    --query "items[?name=='EC2-Controller-API'].id" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_API" ] && [ "$EXISTING_API" != "None" ]; then
    export API_ID="$EXISTING_API"
    echo "✓ API existante: $API_ID"
else
    export API_ID=$(awslocal apigateway create-rest-api \
        --name 'EC2-Controller-API' \
        --query 'id' \
        --output text)
    echo "✓ API créée: $API_ID"
fi

echo "$API_ID" > .api_id

# Récupérer root resource
export ROOT_ID=$(awslocal apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[0].id' \
    --output text)

# Fonction pour créer un endpoint GET
create_endpoint() {
    local ACTION=$1
    
    # Créer ressource
    RESOURCE_ID=$(awslocal apigateway get-resources \
        --rest-api-id $API_ID \
        --query "items[?pathPart=='$ACTION'].id" \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" == "None" ]; then
        RESOURCE_ID=$(awslocal apigateway create-resource \
            --rest-api-id $API_ID \
            --parent-id $ROOT_ID \
            --path-part $ACTION \
            --query 'id' \
            --output text)
    fi
    
    # Créer méthode GET
    awslocal apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method GET \
        --authorization-type NONE \
        --request-parameters method.request.querystring.instance_id=false > /dev/null 2>&1 || true
    
    # Intégration Lambda
    awslocal apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ec2-controller/invocations > /dev/null 2>&1
    
    echo "✓ Endpoint /$ACTION créé"
}

# Créer les 3 endpoints
create_endpoint "start"
create_endpoint "stop"
create_endpoint "status"

# Déployer l'API
awslocal apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod > /dev/null 2>&1

echo "✓ API déployée sur le stage 'prod'"

# Construire les URLs complètes
BASE_URL="${AWS_ENDPOINT}/restapis/$API_ID/prod/_user_request_"
URL_START="${BASE_URL}/start"
URL_STOP="${BASE_URL}/stop"
URL_STATUS="${BASE_URL}/status"

# Sauvegarder les URLs dans des fichiers séparés
echo "$BASE_URL" > .api_url
echo "$URL_START" > .url_start
echo "$URL_STOP" > .url_stop
echo "$URL_STATUS" > .url_status

# Affichage final
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ DÉPLOIEMENT TERMINÉ !                               ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Endpoint AWS : $AWS_ENDPOINT"
echo "🆔 Instance ID  : $INSTANCE_ID"
echo "🔑 API ID       : $API_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URLS DE CONTRÔLE (cliquez ou copiez-collez dans votre navigateur)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "▶️  START  : $URL_START"
echo ""
echo "⏹️  STOP   : $URL_STOP"
echo ""
echo "ℹ️  STATUS : $URL_STATUS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Test rapide : curl -k $URL_STATUS"
echo ""
echo "📖 Documentation : cat README.md"
echo ""
