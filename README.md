# 🚀 API-DRIVEN INFRASTRUCTURE

![Architecture](API_Driven.png)

## 📖 Description

Architecture **Cloud-Native** permettant de contrôler des instances EC2 via une API REST, avec détection automatique de l'environnement (GitHub Codespaces ou local).

**Stack technique :**
- **LocalStack** : Émulateur AWS
- **API Gateway** : Endpoint HTTP REST
- **Lambda** : Fonction serverless Python
- **EC2** : Instance virtuelle contrôlée
- **GitHub Codespaces** : Environnement de développement cloud

---

## 🏗️ Architecture
```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐
│   Client    │─────▶│ API Gateway  │─────▶│   Lambda    │─────▶│   EC2    │
│  (cURL)     │◀─────│   (REST)     │◀─────│  Function   │◀─────│ Instance │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────┘
                              │
                    ┌─────────▼───────────┐
                    │   LocalStack        │
                    │ (Endpoint Dynamique)│
                    └─────────────────────┘
```

**Flux :**
1. Requête HTTP POST → API Gateway
2. API Gateway → Lambda (AWS_PROXY)
3. Lambda → Actions EC2 (start/stop/status)
4. Réponse JSON → Client

---

## 🎯 Innovation Technique

### Détection Automatique d'Environnement

Le projet détecte automatiquement s'il tourne dans **GitHub Codespaces** ou en **local** et configure l'endpoint AWS en conséquence :
```bash
# Codespaces
AWS_ENDPOINT="https://${CODESPACE_NAME}-4566.${DOMAIN}"

# Local
AWS_ENDPOINT="http://localhost:4566"
```

**Avantage :** Aucune modification de code nécessaire, portabilité totale.

### Contournement SSL pour Codespaces

GitHub Codespaces utilise un proxy HTTPS, mais LocalStack n'a pas de certificat valide. Solutions implémentées :

- `PYTHONHTTPSVERIFY=0` pour Python/Boto3
- `--no-verify-ssl` pour AWS CLI
- `curl -k` (insecure) pour les tests

---

## ⚡ Installation et Déploiement

### Prérequis

- GitHub Codespaces OU environnement Linux local
- Python 3.9+
- Docker (pour LocalStack)

### Déploiement Rapide
```bash
# 1. Installer LocalStack
make setup

# 2. Rendre le port 4566 PUBLIC (Codespaces uniquement)
# Onglet PORTS > Port 4566 > Clic droit > Port Visibility > Public

# 3. Déployer l'infrastructure
make deploy

# 4. Tester
make test
```

---

## 🔧 Commandes Disponibles
```bash
make help       # Afficher l'aide
make setup      # Installer et démarrer LocalStack
make deploy     # Déployer toute l'infrastructure
make start      # Démarrer l'instance EC2
make stop       # Arrêter l'instance EC2
make status     # Vérifier le statut de l'instance
make test       # Tester l'API (4 tests automatiques)
make diagnose   # Diagnostic complet de l'infrastructure
make clean      # Tout supprimer et repartir de zéro
```

---

## 🧪 Tests

### Test Automatisé
```bash
make test
```

**Résultat attendu :**
```json
1️⃣  Test: Vérification du statut
{
  "message": "Instance i-xxxxx status: running",
  "instance_id": "i-xxxxx",
  "action": "status",
  "endpoint": "https://xxxxx-4566.app.github.dev"
}

2️⃣  Test: Arrêt de l'instance
{
  "message": "Instance i-xxxxx is stopping",
  ...
}

3️⃣  Test: Vérification après arrêt
{
  "message": "Instance i-xxxxx status: stopped",
  ...
}

4️⃣  Test: Redémarrage de l'instance
{
  "message": "Instance i-xxxxx is starting",
  ...
}

✅ Tests terminés
```

### Test Manuel
```bash
# Charger les variables
source .env

# Vérifier le statut
curl -X POST "$(cat .api_url)" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"status\", \"instance_id\": \"$(cat .instance_id)\"}" \
  -k | jq '.'
```

---

## 📁 Structure du Projet
```
API_Driven/
├── README.md                  # Documentation
├── API_Driven.png             # Schéma d'architecture
├── Makefile                   # Automatisation
├── .gitignore                 # Fichiers à ignorer
├── lambda/
│   └── lambda_function.py     # Fonction Lambda (contrôle EC2)
├── policies/
│   ├── trust-policy.json      # Politique IAM (trust)
│   └── ec2-policy.json        # Politique IAM (permissions EC2)
└── scripts/
    ├── setup_endpoint.sh      # Configuration endpoint dynamique
    ├── deploy.sh              # Déploiement complet
    ├── control_instance.sh    # Contrôle d'instance
    ├── test_api.sh            # Tests automatisés
    └── diagnose.sh            # Diagnostic
```

---

## 🔍 Modifications Techniques Majeures

### 1. Endpoint Dynamique

**Problème :** Hardcoding de `localhost:4566` ne fonctionne pas dans Codespaces.

**Solution :** Script `setup_endpoint.sh` qui détecte l'environnement :
```bash
if [ -n "$CODESPACE_NAME" ]; then
    AWS_ENDPOINT="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
    AWS_ENDPOINT="http://localhost:4566"
fi
```

### 2. Wrapper awslocal

**Problème :** Conflit avec Ruby/RVM cassait `awslocal`.

**Solution :** Fonction Bash personnalisée dans `deploy.sh` :
```bash
awslocal() {
    aws --endpoint-url="$AWS_ENDPOINT" \
        --no-verify-ssl \
        "$@"
}
```

### 3. Gestion SSL/TLS

**Problème :** Proxy HTTPS de Codespaces + certificat invalide de LocalStack.

**Solution :**
- `export PYTHONHTTPSVERIFY=0`
- `--no-verify-ssl` pour AWS CLI
- `curl -k` pour les requêtes HTTP

### 4. Robustesse du Déploiement

**Améliorations :**
- Vérification de l'existence des ressources avant création
- Gestion des erreurs de permissions (`my-key.pem`)
- Idempotence : relancer `make deploy` ne crée pas de doublons

---

## 🐛 Troubleshooting

### LocalStack non accessible
```bash
# Vérifier que LocalStack tourne
localstack status services

# Vérifier l'endpoint
cat .env

# Test de connectivité
curl -k "$(cat .env | grep AWS_ENDPOINT | cut -d'"' -f2)/_localstack/health"
```

### Port 4566 non public (Codespaces)

1. Onglet **PORTS** (en bas)
2. Trouver le port **4566**
3. Colonne **Visibility** → **Public**
4. Attendre 10 secondes
5. Relancer `make deploy`

### API ne répond pas
```bash
# Diagnostic complet
make diagnose

# Recréer l'infrastructure
make clean
make deploy
```

### Erreur "awslocal: command not found"
```bash
pip install --upgrade awscli-local
```

---

## 🎓 Concepts Clés

### Cloud-Native

Architecture portable entre environnements grâce à la détection automatique et la configuration dynamique.

### Infrastructure as Code (IaC)

Toute l'infrastructure est définie en code (scripts Bash, politiques JSON, fonction Python), permettant :
- Reproductibilité
- Versioning Git
- Automatisation complète

### Serverless

Lambda fonctionne sans gestion de serveurs, déclenchée uniquement par les requêtes API.

### API-Driven

L'infrastructure est pilotée par des appels API REST, pas par une console graphique.
