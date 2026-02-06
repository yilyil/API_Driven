#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║              🔍 VÉRIFICATION COMPLÈTE DU PROJET                            ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# 1. État Git
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  État Git"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git status --short
if [ -z "$(git status --short)" ]; then
    echo "✅ Tout est commité"
else
    echo "⚠️  Fichiers non commités trouvés"
fi

# 2. Recherche localhost dans le code
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Recherche de 'localhost' dans le code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LOCALHOST_COUNT=0

# Lambda
if grep -q "localhost" lambda/lambda_function.py 2>/dev/null; then
    echo "❌ lambda/lambda_function.py contient 'localhost'"
    grep -n "localhost" lambda/lambda_function.py
    LOCALHOST_COUNT=$((LOCALHOST_COUNT + 1))
else
    echo "✅ lambda/lambda_function.py - Clean"
fi

# Scripts
for script in scripts/*.sh; do
    if grep -q "localhost" "$script" 2>/dev/null; then
        echo "⚠️  $script contient 'localhost'"
        grep -n "localhost" "$script"
        LOCALHOST_COUNT=$((LOCALHOST_COUNT + 1))
    else
        echo "✅ $script - Clean"
    fi
done

# Makefile
if grep -q "localhost" Makefile 2>/dev/null; then
    echo "❌ Makefile contient 'localhost'"
    grep -n "localhost" Makefile
    LOCALHOST_COUNT=$((LOCALHOST_COUNT + 1))
else
    echo "✅ Makefile - Clean"
fi

# 3. Vérification des fichiers sensibles
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Vérification de la structure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REQUIRED_FILES=(
    "README.md"
    "Makefile"
    ".gitignore"
    "lambda/lambda_function.py"
    "policies/trust-policy.json"
    "policies/ec2-policy.json"
    "scripts/setup_endpoint.sh"
    "scripts/deploy.sh"
    "scripts/control_instance.sh"
    "scripts/test_api.sh"
    "scripts/diagnose.sh"
    "show_urls.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file MANQUANT"
    fi
done

# 4. Vérification des permissions
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Permissions des scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for script in scripts/*.sh show_urls.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script - Exécutable"
    else
        echo "❌ $script - Pas exécutable"
    fi
done

# 5. Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $LOCALHOST_COUNT -eq 0 ]; then
    echo "✅ AUCUNE dépendance localhost trouvée dans le code"
else
    echo "❌ $LOCALHOST_COUNT fichier(s) contiennent 'localhost'"
    echo "⚠️  NOTE: 'localhost' dans README.md est OK (documentation uniquement)"
fi

echo ""
echo "📊 Derniers commits:"
git log --oneline -5

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                          ✅ VÉRIFICATION TERMINÉE                          ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
