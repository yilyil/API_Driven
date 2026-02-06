# 🚀 API-DRIVEN INFRASTRUCTURE - GitHub Codespaces

![Architecture](API_Driven.png)

> ⚠️ **Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces**  
> Il ne peut pas être exécuté en local car il est conçu pour l'infrastructure cloud de GitHub.

## 📖 Description

Architecture **Cloud-Native** permettant de contrôler des instances EC2 via une API REST dans GitHub Codespaces. Ce projet démontre l'orchestration de services AWS serverless pour piloter dynamiquement des ressources d'infrastructure, indépendamment de toute console graphique.

**Stack Technique :**
- **GitHub Codespaces** : Environnement de développement cloud (REQUIS)
- **LocalStack** : Émulateur AWS complet
- **API Gateway** : Point d'entrée HTTP REST
- **Lambda** : Fonction serverless Python
- **EC2** : Instances virtuelles contrôlées

---

## 🏗️ Architecture
```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐
│   Client    │─────▶│ API Gateway  │─────▶│   Lambda    │─────▶│   EC2    │
│  (HTTP)     │◀─────│   (REST)     │◀─────│  Function   │◀─────│ Instance │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────┘
                              │
                    ┌─────────▼──────────┐
                    │   LocalStack       │
                    │ GitHub Codespaces  │
                    │ (Port 4566 Public) │
                    └────────────────────┘
```

**Flux de données :**
1. Client → Requête HTTP POST avec action (start/stop/status)
2. API Gateway → Transmission à Lambda (intégration AWS_PROXY)
3. Lambda → Exécution de l'action sur l'instance EC2
4. Réponse JSON → Client via API Gateway

---

## ⚡ Installation et Déploiement

### Étape 1 : Créer un Codespace

1. Aller sur https://github.com/yilyil/API_Driven
2. Cliquer sur **"Code"** > **"Codespaces"**
3. Cliquer sur **"Create codespace on main"**
4. Attendre l'ouverture de l'environnement VS Code dans le navigateur

### Étape 2 : Installer LocalStack
```bash
make setup
```

**Résultat attendu :**
```
✅ LocalStack démarré
⚠️  IMPORTANT (Codespaces uniquement):
    Rendez le port 4566 PUBLIC dans l'onglet PORTS
```

### Étape 3 : Rendre le Port 4566 Public

**CRUCIAL** : Sans cette étape, rien ne fonctionnera !

1. En bas de l'interface Codespaces, cliquer sur l'onglet **"PORTS"**
2. Trouver la ligne avec le port **4566**
3. Dans la colonne **"Visibility"**, cliquer sur **"Private"**
4. Sélectionner **"Public"**
5. **Attendre 10-15 secondes** que le changement prenne effet

### Étape 4 : Déployer l'Infrastructure
```bash
make deploy
```

**Résultat attendu :**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DÉPLOIEMENT TERMINÉ !
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Endpoint AWS: https://psychic-orbit-xxxxx-4566.app.github.dev
🆔 Instance ID: i-abc123def456
🔗 API URL: https://psychic-orbit-xxxxx-4566.app.github.dev/restapis/abc123/prod/_user_request_/ec2

💡 Pour tester: make test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Étape 5 : Tester l'API
```bash
make test
```

---

## 🎮 Utilisation

### Commandes Make
```bash
make help       # Afficher toutes les commandes
make setup      # Installer LocalStack
make deploy     # Déployer l'infrastructure
make status     # Vérifier l'état de l'instance
make stop       # Arrêter l'instance EC2
make start      # Démarrer l'instance EC2
make test       # Lancer les 4 tests automatiques
make diagnose   # Diagnostic complet
make clean      # Tout supprimer
```

### 🧪 Tests Automatiques
```bash
make test
```

**Sortie attendue :**
```json
🧪 Test de l'API EC2 Controller
================================
📍 Endpoint: https://xxxxx-4566.app.github.dev
🆔 Instance: i-abc123def456

1️⃣  Test: Vérification du statut
{
  "message": "Instance i-abc123def456 status: running",
  "instance_id": "i-abc123def456",
  "action": "status",
  "endpoint": "https://xxxxx-4566.app.github.dev"
}

2️⃣  Test: Arrêt de l'instance
{
  "message": "Instance i-abc123def456 is stopping",
  ...
}

3️⃣  Test: Vérification après arrêt
{
  "message": "Instance i-abc123def456 status: stopped",
  ...
}

4️⃣  Test: Redémarrage de l'instance
{
  "message": "Instance i-abc123def456 is starting",
  ...
}

✅ Tests terminés
```

### 📡 Utilisation Manuelle avec cURL
```bash
# Charger les variables
source .env

# Récupérer les informations
API_URL=$(cat .api_url)
INSTANCE_ID=$(cat .instance_id)

# Vérifier le statut
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"status\", \"instance_id\": \"$INSTANCE_ID\"}" \
  -k | jq '.'

# Arrêter l'instance
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"stop\", \"instance_id\": \"$INSTANCE_ID\"}" \
  -k | jq '.'

# Démarrer l'instance
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"start\", \"instance_id\": \"$INSTANCE_ID\"}" \
  -k | jq '.'
```

---

## 📁 Structure du Projet
```
API_Driven/
├── README.md                    # Documentation
├── API_Driven.png              # Diagramme d'architecture
├── Makefile                    # Automatisation
├── .gitignore                  # Fichiers exclus
│
├── lambda/
│   └── lambda_function.py      # Fonction Lambda (contrôle EC2)
│
├── policies/
│   ├── trust-policy.json       # Politique de confiance IAM
│   └── ec2-policy.json         # Permissions EC2
│
└── scripts/
    ├── setup_endpoint.sh       # Configuration Codespace
    ├── deploy.sh               # Déploiement complet
    ├── control_instance.sh     # Contrôle d'instance
    ├── test_api.sh             # Tests automatiques
    └── diagnose.sh             # Diagnostic
```

---

## 🎯 Innovation : Zéro Dépendance Localhost

### Pourquoi Codespaces Only ?

L'énoncé de l'atelier stipule explicitement :
> "exécuté dans GitHub Codespaces"

Ce projet ne fonctionne **que** dans Codespaces car :

1. **Pas de localhost** : Tout passe par l'URL publique du Codespace
2. **Détection automatique** : Le script vérifie la présence de `$CODESPACE_NAME`
3. **Configuration dynamique** : L'endpoint AWS est construit à partir des variables Codespace

### Comment ça marche ?
```bash
# Dans setup_endpoint.sh
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ ERREUR: Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"
    exit 1
fi

# Construction de l'URL
CODESPACE_PORT_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

### Exemple d'URL Généré
```
https://psychic-orbit-wqgx95qp6wx2gq46-4566.app.github.dev/restapis/2xjksubvvi/prod/_user_request_/ec2
```

---

## 🔍 Modifications Techniques

### 1. Vérification Codespace Stricte

**scripts/setup_endpoint.sh** et **scripts/deploy.sh** arrêtent l'exécution si `$CODESPACE_NAME` est absent.

### 2. Wrapper awslocal Personnalisé
```bash
awslocal() {
    aws --endpoint-url="$AWS_ENDPOINT" \
        --no-verify-ssl \
        "$@"
}
export -f awslocal
export PYTHONHTTPSVERIFY=0
```

### 3. Lambda Sans Fallback

La fonction Lambda retourne une erreur explicite si `AWS_ENDPOINT` n'est pas défini :
```python
aws_endpoint = os.environ.get('AWS_ENDPOINT')

if not aws_endpoint:
    return {
        'statusCode': 500,
        'body': json.dumps({
            'error': 'AWS_ENDPOINT not configured'
        })
    }
```

### 4. Déploiement Idempotent

Le script vérifie l'existence des ressources avant de les créer :
- Pas de doublons d'instances EC2
- Mise à jour du code Lambda si existe déjà
- Réutilisation de l'API Gateway si présente

---

## 🐛 Troubleshooting

### ❌ "Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"

**Cause :** Vous essayez d'exécuter en local.

**Solution :** Créer un Codespace sur GitHub :
1. https://github.com/yilyil/API_Driven
2. Code > Codespaces > Create codespace

### ❌ "Impossible de se connecter à LocalStack"

**Causes possibles :**

1. **LocalStack pas démarré**
```bash
make setup
```

2. **Port 4566 non public**
- Onglet PORTS → Port 4566 → Public
- Attendre 10-15 secondes

3. **Test de connectivité**
```bash
source .env
curl -k "$AWS_ENDPOINT/_localstack/health" | jq
```

### ❌ API ne répond pas
```bash
# Diagnostic complet
make diagnose

# Recréer proprement
make clean
make deploy
```

---

## 🎓 Concepts Clés

### Cloud-Native Architecture

**Définition :** Application conçue pour fonctionner exclusivement dans le cloud.

**Avantages :**
- ✅ Pas d'installation locale
- ✅ Environnement reproductible
- ✅ Collaboration facilitée
- ✅ Pas de configuration machine

### Infrastructure as Code (IaC)

Toute l'infrastructure est définie en code :
- Scripts Bash pour l'orchestration
- Politiques JSON pour IAM
- Fonction Python pour la logique métier
- Makefile pour l'automatisation

### API-Driven Infrastructure

L'infrastructure est contrôlée par API :
- Pas de console graphique
- Scriptable et automatisable
- Intégration CI/CD facile
- Découplage client/serveur
