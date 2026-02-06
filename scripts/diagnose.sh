#!/bin/bash

echo "🔍 DIAGNOSTIC - API-Driven Infrastructure"
echo "=========================================="
echo ""

# Charger les variables
if [ -f .env ]; then
    source .env
fi

# Vérifier LocalStack
echo "1️⃣  LocalStack Status:"
localstack status services
echo ""

# Vérifier les instances EC2
echo "2️⃣  Instances EC2:"
awslocal ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table
echo ""

# Vérifier les fonctions Lambda
echo "3️⃣  Fonctions Lambda:"
awslocal lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output table
echo ""

# Vérifier les APIs
echo "4️⃣  API Gateway:"
awslocal apigateway get-rest-apis --query 'items[*].[id,name,createdDate]' --output table
echo ""

# Vérifier les rôles IAM
echo "5️⃣  Rôles IAM:"
awslocal iam list-roles --query 'Roles[*].[RoleName,CreateDate]' --output table
echo ""

# Vérifier les fichiers de configuration
echo "6️⃣  Fichiers de configuration:"
echo "Endpoint: ${AWS_ENDPOINT:-Non configuré}"

if [ -f .instance_id ]; then
    echo "✓ Instance ID: $(cat .instance_id)"
else
    echo "✗ Fichier .instance_id manquant"
fi

if [ -f .api_id ]; then
    echo "✓ API ID: $(cat .api_id)"
else
    echo "✗ Fichier .api_id manquant"
fi

if [ -f .api_url ]; then
    echo "✓ API URL: $(cat .api_url)"
else
    echo "✗ Fichier .api_url manquant"
fi

echo ""
echo "✅ Diagnostic terminé"
