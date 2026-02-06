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
    echo "❌ Fichier .env manquant. Exécutez d'abord: bash scripts/setup_endpoint.sh"
    exit 1
fi

echo "📍 Endpoint AWS: $AWS_ENDPOINT"

# Configurer AWS CLI pour utiliser l'endpoint
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export PYTHONHTTPSVERIFY=0

# Test de connexion avec curl
echo ""
echo "🔌 Test de connexion à LocalStack..."
HEALTH_CHECK=$(curl -s -k "$AWS_ENDPOINT/_localstack/health" 2>/dev/null || echo "")

if [ -z "$HEALTH_CHECK" ]; then
    echo "❌ Impossible de se connecter à LocalStack"
    echo ""
    echo "Vérifiez que:"
    echo "  1. LocalStack est démarré: make setup"
    echo "  2. Le port 4566 est PUBLIC dans l'onglet PORTS de Codespaces"
    echo "  3. Attendre 30 secondes après avoir rendu le port public"
    echo ""
    echo "Test manuel:"
    echo "  curl -k $AWS_ENDPOINT/_localstack/health"
    exit 1
fi

echo "✓ Connexion à LocalStack OK"

# 1. Création de l'instance EC2
echo ""
echo "📦 Création de l'instance EC2..."

# Créer Key Pair
if [ -f my-key.pem ]; then
    rm -f my-key.pem
fi

aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    ec2 create-key-pair \
    --key-name my-key \
    --query 'KeyMaterial' \
    --output text > my-key.pem 2>/dev/null || echo "✓ Key pair existe déjà"

if [ -f my-key.pem ]; then
    chmod 400 my-key.pem
    echo "✓ Key pair créée"
fi

# Créer Security Group
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    ec2 create-security-group \
    --group-name my-sg \
    --description "Security group for API-driven EC2" 2>/dev/null || echo "✓ Security group existe déjà"

# Vérifier si l'instance existe déjà
EXISTING_INSTANCE=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    ec2 describe-instances \
    --filters "Name=tag:Name,Values=API-Driven-Instance" \
              "Name=instance-state-name,Values=running,stopped,pending" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

if [ "$EXISTING_INSTANCE" != "None" ] && [ -n "$EXISTING_INSTANCE" ] && [ "$EXISTING_INSTANCE" != "null" ]; then
    echo "✓ Instance existante trouvée: $EXISTING_INSTANCE"
    export INSTANCE_ID="$EXISTING_INSTANCE"
else
    echo "→ Création d'une nouvelle instance..."
    aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        ec2 run-instances \
        --image-id ami-ff0fea8310f3 \
        --count 1 \
        --instance-type t2.micro \
        --key-name my-key \
        --security-groups my-sg \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=API-Driven-Instance}]' > /dev/null
    
    sleep 2
    
    export INSTANCE_ID=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        ec2 describe-instances \
        --filters "Name=tag:Name,Values=API-Driven-Instance" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
fi

echo "✓ Instance ID: $INSTANCE_ID"
echo "$INSTANCE_ID" > .instance_id

# 2. Création de la fonction Lambda
echo ""
echo "⚡ Création de la fonction Lambda..."
cd lambda

# Créer le zip
if [ -f lambda_function.zip ]; then
    rm lambda_function.zip
fi
zip -q lambda_function.zip lambda_function.py
echo "✓ Package Lambda créé"

# Créer le rôle IAM
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    iam create-role \
    --role-name lambda-ec2-role \
    --assume-role-policy-document file://../policies/trust-policy.json > /dev/null 2>&1 || echo "✓ Rôle IAM existe déjà"

# Attacher la politique
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    iam put-role-policy \
    --role-name lambda-ec2-role \
    --policy-name EC2Access \
    --policy-document file://../policies/ec2-policy.json > /dev/null
echo "✓ Politique attachée"

# Créer ou mettre à jour la fonction Lambda
LAMBDA_EXISTS=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    lambda get-function \
    --function-name ec2-controller 2>/dev/null || echo "")

if [ -z "$LAMBDA_EXISTS" ]; then
    aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        lambda create-function \
        --function-name ec2-controller \
        --runtime python3.9 \
        --role arn:aws:iam::000000000000:role/lambda-ec2-role \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip \
        --environment Variables="{INSTANCE_ID=$INSTANCE_ID,AWS_ENDPOINT=$AWS_ENDPOINT}" \
        --timeout 30 > /dev/null
    echo "✓ Lambda créée"
else
    aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        lambda update-function-code \
        --function-name ec2-controller \
        --zip-file fileb://lambda_function.zip > /dev/null
    echo "✓ Code Lambda mis à jour"
fi

# Mettre à jour les variables d'environnement
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    lambda update-function-configuration \
    --function-name ec2-controller \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID,AWS_ENDPOINT=$AWS_ENDPOINT}" > /dev/null
echo "✓ Variables d'environnement Lambda configurées"

cd ..

# 3. Création de l'API Gateway
echo ""
echo "🌐 Création de l'API Gateway..."

# Vérifier si l'API existe
EXISTING_API=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway get-rest-apis \
    --query "items[?name=='EC2-Controller-API'].id" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_API" ] && [ "$EXISTING_API" != "None" ] && [ "$EXISTING_API" != "null" ]; then
    echo "✓ API existante trouvée: $EXISTING_API"
    export API_ID="$EXISTING_API"
else
    echo "→ Création d'une nouvelle API..."
    export API_ID=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        apigateway create-rest-api \
        --name 'EC2-Controller-API' \
        --description 'API to control EC2 instances' \
        --query 'id' \
        --output text)
fi

echo "✓ API ID: $API_ID"
echo "$API_ID" > .api_id

# Récupérer le root resource
export ROOT_ID=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[0].id' \
    --output text)

# Créer ou récupérer la ressource /ec2
EXISTING_RESOURCE=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway get-resources \
    --rest-api-id $API_ID \
    --query "items[?pathPart=='ec2'].id" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_RESOURCE" ] && [ "$EXISTING_RESOURCE" != "None" ] && [ "$EXISTING_RESOURCE" != "null" ]; then
    export RESOURCE_ID="$EXISTING_RESOURCE"
    echo "✓ Ressource /ec2 existe déjà"
else
    export RESOURCE_ID=$(aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
        apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_ID \
        --path-part ec2 \
        --query 'id' \
        --output text)
    echo "✓ Ressource /ec2 créée"
fi

# Configurer la méthode POST
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE > /dev/null 2>&1 || echo "✓ Méthode POST existe déjà"

# Intégrer avec Lambda
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ec2-controller/invocations > /dev/null 2>&1

echo "✓ Intégration Lambda configurée"

# Déployer l'API
aws --endpoint-url="$AWS_ENDPOINT" --no-verify-ssl \
    apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod > /dev/null 2>&1
echo "✓ API déployée sur le stage 'prod'"

# Construire l'URL de l'API
export API_URL="${AWS_ENDPOINT}/restapis/$API_ID/prod/_user_request_/ec2"
echo "$API_URL" > .api_url

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Endpoint AWS: $AWS_ENDPOINT"
echo "🆔 Instance ID: $INSTANCE_ID"
echo "🔗 API URL: $API_URL"
echo ""
echo "💡 Pour tester: make test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
