# 🚀 API-DRIVEN INFRASTRUCTURE

> 🎯 **Architecture Cloud-Native permettant de piloter des instances EC2 via de simples URLs HTTP GET**

## 📖 Description

Projet d'infrastructure API-driven démontrant l'orchestration de services AWS serverless (API Gateway + Lambda) pour contrôler dynamiquement des ressources d'infrastructure EC2, sans aucune console graphique. 

### Stack Technique

- **GitHub Codespaces** : Environnement de développement cloud (OBLIGATOIRE)
- **LocalStack** : Émulateur AWS complet (API Gateway, Lambda, EC2, IAM)
- **API Gateway** : 3 endpoints REST GET (`/start`, `/stop`, `/status`)
- **AWS Lambda** : Fonction serverless Python avec Boto3
- **Amazon EC2** : Instance virtuelle contrôlée via l'API

---

## 🏗️ Architecture
```
┌─────────────────┐
│   Navigateur    │  Requête HTTP GET
│   ou cURL       │  
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Codespaces (Port 4566 Public)           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                     LocalStack                         │ │
│  │                                                        │ │
│  │  ┌──────────────┐    ┌─────────────┐    ┌──────────┐   │ │
│  │  │ API Gateway  │───▶│   Lambda    │───▶│   EC2    │   │ │
│  │  │   /start     │    │  Function   │    │ Instance │   │ │
│  │  │   /stop      │    │  (Python)   │    │          │   │ │
│  │  │   /status    │    │             │    │          │   │ │
│  │  └──────────────┘    └─────────────┘    └──────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Flux de Données

1. **Client** → Requête HTTP GET vers `/start`, `/stop`, ou `/status`
2. **API Gateway** → Reçoit la requête et déclenche la fonction Lambda
3. **Lambda** → Extrait l'action depuis le path de l'URL
4. **Lambda** → Exécute l'action sur l'instance EC2 via le SDK Boto3
5. **Réponse JSON** → Retourne via API Gateway au client

---

## ⚡ Installation et Déploiement

### Prérequis

- Compte GitHub avec accès à Codespaces
- **AUCUNE installation locale requise** (tout s'exécute dans le cloud)

### 🚀 Déploiement en 4 Étapes

#### Étape 1 : Créer un Codespace

1. Aller sur **[https://github.com/[...]/API_Driven](https://github.com/[...]/API_Driven)**
2. Cliquer sur **Code** > **Codespaces** > **Create codespace on main**
3. Attendre l'ouverture de VS Code dans le navigateur (≈ 30 secondes)

#### Étape 2 : Installer LocalStack et AWS CLI
```bash
make setup
```

**Ce que fait cette commande :**
- ✅ Installe AWS CLI v2
- ✅ Installe LocalStack et awscli-local
- ✅ Démarre LocalStack en mode daemon
- ✅ Vérifie que tous les services AWS sont disponibles

**Temps d'exécution :** ≈ 1 minute

#### Étape 3 : Configuration Automatique du Port

Le port 4566 est automatiquement configuré en **PUBLIC** par le script de déploiement via `gh codespace ports visibility`.

#### Étape 4 : Déployer l'Infrastructure
```bash
make deploy
```

**Ce que fait cette commande :**
1. Configure l'endpoint AWS pour Codespaces
2. Crée une instance EC2 avec key pair et security group
3. Déploie la fonction Lambda avec les bonnes permissions IAM
4. Crée l'API Gateway avec 3 endpoints GET
5. Génère et affiche les 3 URLs de contrôle

**Résultat attendu :**
```
╔════════════════════════════════════════════════════════════════════════════╗
║                     ✅ DÉPLOIEMENT TERMINÉ !                               ║
╚════════════════════════════════════════════════════════════════════════════╝

📍 Endpoint AWS : https://psychic-orbit-xxx-4566.app.github.dev
🆔 Instance ID  : i-abc123def456
🔑 API ID       : ioet26ozcx

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 URLS DE CONTRÔLE (cliquez ou copiez-collez dans votre navigateur)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶️  START  : https://[...].app.github.dev/restapis/ioet26ozcx/prod/_user_request_/start

⏹️  STOP   : https://[...].app.github.dev/restapis/ioet26ozcx/prod/_user_request_/stop

ℹ️  STATUS : https://[...].app.github.dev/restapis/ioet26ozcx/prod/_user_request_/status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🎮 Utilisation de l'API

### 🌐 Méthode 1 : Navigateur Web (Le plus simple !)

Ouvrez directement les URLs dans votre navigateur. Pas besoin de Postman ou d'outils complexes !

**Exemple d'utilisation :**
```
1. Copiez l'URL STATUS et ouvrez-la dans un nouvel onglet
2. Vous verrez une réponse JSON comme :
   {
     "message": "Instance i-abc123def456 status: running",
     "instance_id": "i-abc123def456",
     "action": "status"
   }
```

### 💻 Méthode 2 : Terminal avec cURL
```bash
# Charger les URLs depuis les fichiers générés
URL_START=$(cat .url_start)
URL_STOP=$(cat .url_stop)
URL_STATUS=$(cat .url_status)

# Vérifier le statut de l'instance
curl -k "$URL_STATUS" | jq '.'

# Arrêter l'instance
curl -k "$URL_STOP" | jq '.'

# Attendre 3 secondes
sleep 3

# Vérifier que l'instance est arrêtée
curl -k "$URL_STATUS" | jq '.'

# Redémarrer l'instance
curl -k "$URL_START" | jq '.'
```

### ⚙️ Méthode 3 : Commandes Make (Recommandé)
```bash
make status     # Vérifier l'état de l'instance
make stop       # Arrêter l'instance EC2
make start      # Démarrer l'instance EC2
make test       # Lancer les 4 tests automatiques
make urls       # Réafficher les 3 URLs
make diagnose   # Diagnostic complet de l'infrastructure
make clean      # Tout supprimer et repartir de zéro
```

---

## 🧪 Tests Automatiques
```bash
make test
```

**Sortie attendue :**
```
╔════════════════════════════════════════════════════════════════════════════╗
║                🧪 TESTS DE L'API EC2 CONTROLLER                            ║
╚════════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣  Test STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 URL : https://xxx-4566.app.github.dev/restapis/abc123/prod/_user_request_/status

{
  "message": "Instance i-abc123 status: running",
  "instance_id": "i-abc123",
  "action": "status"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2️⃣  Test STOP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 URL : https://xxx-4566.app.github.dev/restapis/abc123/prod/_user_request_/stop

{
  "message": "Instance i-abc123 is stopping",
  "instance_id": "i-abc123",
  "action": "stop"
}

⏳ Attente de 3 secondes...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3️⃣  Test STATUS (après STOP)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{
  "message": "Instance i-abc123 status: stopped",
  "instance_id": "i-abc123",
  "action": "status"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4️⃣  Test START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{
  "message": "Instance i-abc123 is starting",
  "instance_id": "i-abc123",
  "action": "start"
}

╔════════════════════════════════════════════════════════════════════════════╗
║                          ✅ TESTS TERMINÉS                                 ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## 📁 Structure du Projet
```
API_Driven/
├── README.md                       # Cette documentation
├── API_Driven.png                  # Diagramme d'architecture
├── Makefile                        # Automatisation (setup, deploy, test, clean)
├── .gitignore                      # Fichiers à exclure du versioning
├── show_urls.sh                    # Script pour réafficher les URLs
├── verify_project.sh               # Script de vérification complète
│
├── lambda/
│   └── lambda_function.py          # Fonction Lambda (contrôle EC2)
│                                   # - Extrait l'action depuis le path
│                                   # - Utilise Boto3 pour EC2
│                                   # - AUCUNE dépendance localhost
│
├── policies/
│   ├── trust-policy.json           # Politique de confiance IAM (AssumeRole)
│   └── ec2-policy.json             # Permissions EC2 pour Lambda
│
└── scripts/
    ├── setup_endpoint.sh           # Détection Codespace + port automatique
    ├── deploy.sh                   # Déploiement complet (EC2, Lambda, API)
    ├── control_instance.sh         # Contrôle manuel d'instance
    ├── test_api.sh                 # Suite de tests automatiques
    └── diagnose.sh                 # Diagnostic de l'infrastructure
```

---

## 🎯 Innovations Techniques

### 1. 🌐 Zéro Dépendance Localhost

**Problématique :** Les tutoriels classiques hard-codent `localhost:4566`, incompatible avec Codespaces.

**Solution :** Détection automatique de l'environnement Codespace et construction dynamique de l'URL.
```bash
# scripts/setup_endpoint.sh
if [ -z "$CODESPACE_NAME" ]; then
    echo "❌ Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"
    exit 1
fi

CODESPACE_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

**Résultat :** Portabilité totale entre différents Codespaces, aucune configuration manuelle.

### 2. 🔓 Port Public Automatique

**Problématique :** Le port 4566 est privé par défaut dans Codespaces.

**Solution :** Utilisation de `gh codespace ports visibility` pour automatiser.
```bash
gh codespace ports visibility 4566:public -c $CODESPACE_NAME
```

**Résultat :** Plus besoin de configuration manuelle via l'interface.

### 3. 🎯 API GET Simple

**Problématique :** Les APIs traditionnelles POST + JSON body sont complexes à tester.

**Solution :** 3 endpoints GET simples, ouvrables directement dans le navigateur.
```
/start  → Démarre l'instance
/stop   → Arrête l'instance
/status → Affiche l'état
```

**Code Lambda :**
```python
path = event.get('path', '')
action = path.split('/')[-1].lower()  # Extrait 'start', 'stop' ou 'status'

if action == 'start':
    ec2.start_instances(InstanceIds=[instance_id])
elif action == 'stop':
    ec2.stop_instances(InstanceIds=[instance_id])
elif action == 'status':
    response = ec2.describe_instances(InstanceIds=[instance_id])
    state = response['Reservations'][0]['Instances'][0]['State']['Name']
```

**Avantages :**
- ✅ Testable dans le navigateur
- ✅ Bookmarkable
- ✅ Partageable
- ✅ Pas besoin de Postman

### 4. ⚙️ Installation Automatique d'AWS CLI

**Problématique :** AWS CLI v2 n'est pas préinstallé dans Codespaces.

**Solution :** Installation automatique dans le Makefile.
```bash
# Makefile - target setup
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
```

### 5. 🔒 Gestion SSL/TLS

**Problématique :** Codespaces utilise HTTPS mais LocalStack a un certificat invalide.

**Solutions implémentées :**
- `awslocal` : Utilise automatiquement `--no-verify-ssl`
- `curl` : Flag `-k` (insecure)
- Lambda Boto3 : `verify=False` dans le client EC2

### 6. ♻️ Déploiement Idempotent

**Problématique :** Relancer le déploiement après une erreur crée des doublons.

**Solution :** Vérification de l'existence avant création.
```bash
EXISTING_INSTANCE=$(awslocal ec2 describe-instances \
    --filters "Name=tag:Name,Values=API-Driven-Instance" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

if [ "$EXISTING_INSTANCE" != "None" ]; then
    echo "✓ Instance existante: $EXISTING_INSTANCE"
    export INSTANCE_ID="$EXISTING_INSTANCE"
else
    # Créer nouvelle instance
fi
```

**Résultat :** Le script peut être relancé sans créer de ressources en double.

---

## 🐛 Troubleshooting

### ❌ "Ce projet fonctionne UNIQUEMENT dans GitHub Codespaces"

**Cause :** Vous essayez d'exécuter en local.

**Solution :** Créez un Codespace sur GitHub.

### ❌ "Impossible de se connecter à LocalStack"

**Diagnostic :**
```bash
# 1. Vérifier que LocalStack tourne
localstack status services

# 2. Vérifier l'endpoint configuré
cat .env

# 3. Tester manuellement la connexion
source .env
curl -k "$AWS_ENDPOINT/_localstack/health" | jq
```

**Solutions :**
1. LocalStack pas démarré → `make setup`
2. Port 4566 non public → Le script le fait automatiquement, mais vous pouvez vérifier dans l'onglet PORTS
3. Attendre 10-15 secondes après le démarrage de LocalStack

### ❌ Les URLs ne répondent pas
```bash
# Test de connectivité
source .env
curl -k "$AWS_ENDPOINT/_localstack/health"

# Si ça ne marche pas, nettoyer et redéployer
make clean
make setup
# Attendre 15 secondes
make deploy
```

### ❌ "aws: command not found"

**Cause :** AWS CLI pas installé.

**Solution :**
```bash
make setup  # Installe automatiquement AWS CLI
```

### 🔍 Diagnostic Complet
```bash
# Lance un diagnostic exhaustif
make diagnose

# Affiche :
# - État de LocalStack
# - Configuration de l'endpoint
# - Instance EC2
# - Fonction Lambda
# - API Gateway
# - URLs générées
```

---

## 🎓 Concepts Clés

### Cloud-Native Architecture

**Définition :** Application conçue pour fonctionner exclusivement dans le cloud, sans capacité d'exécution locale.

**Caractéristiques :**
- Configuration dynamique (détection automatique de l'environnement)
- Pas de dépendances hard-codées (pas de `localhost:4566`)
- Variables d'environnement pour toute la configuration
- Infrastructure définie en code (IaC)

**Avantages :**
- ✅ Reproductibilité parfaite
- ✅ Pas de "ça marche sur ma machine"
- ✅ Collaboration facilitée
- ✅ Environnement identique pour tous

### Infrastructure as Code (IaC)

Toute l'infrastructure est définie en code versionné :

| Composant | Langage | Fichier |
|-----------|---------|---------|
| Orchestration | Bash | `scripts/deploy.sh` |
| Automatisation | Makefile | `Makefile` |
| Politiques IAM | JSON | `policies/*.json` |
| Logique métier | Python | `lambda/lambda_function.py` |

**Bénéfices :**
- Versioning complet avec Git
- Documentation vivante (le code = la doc)
- Déploiements automatisés et reproductibles
- Facilite les rollbacks et les tests

### API-Driven Infrastructure

L'infrastructure est pilotée par API, pas par console graphique.

**Workflow traditionnel :**
```
Humain → Console AWS Web → Clic sur boutons → Action sur EC2
         (Interface graphique)
```

**Workflow API-Driven (ce projet) :**
```
Humain → URL HTTP GET → API Gateway → Lambda → Action sur EC2
         (Programmable)
```

**Avantages :**
- ✅ Scriptable et automatisable
- ✅ Intégration CI/CD native
- ✅ Pas de dépendance à une UI
- ✅ Testable automatiquement
- ✅ Découplage client/serveur

### Serverless Computing

**Lambda = Compute sans serveur :**
```
Requête GET /start 
  → Lambda s'exécute (< 1 seconde)
  → EC2 démarre
  → Lambda s'arrête automatiquement
  → Coût ≈ 0€ (gratuit avec LocalStack)
```

**Caractéristiques :**
- Pas de VM à gérer ou maintenir
- Pas de mise à l'échelle manuelle
- Déclenchement par événements
- Facturation à l'usage (par requête)

---

## 📚 Ressources

### Documentation Officielle

- [GitHub Codespaces](https://docs.github.com/en/codespaces)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [Boto3 SDK Python](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

### Concepts Avancés

- [AWS_PROXY Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [IAM Policies and Permissions](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [API Gateway GET Methods](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-method-settings-method-request.html)

---

## 📝 Commandes Rapides
```bash
# Installation et déploiement complet
make setup && make deploy

# Tester l'API
make test

# Réafficher les URLs
make urls

# Diagnostic complet
make diagnose

# Tout nettoyer et recommencer
make clean && make setup && make deploy

# Vérifier l'intégrité du projet
./verify_project.sh
```

---

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-yilyil-blue?style=flat&logo=github)](https://github.com/yilyil/API_Driven)
[![Codespaces](https://img.shields.io/badge/Codespaces-Ready-green?style=flat&logo=github)](https://github.com/yilyil/API_Driven)

</div>
