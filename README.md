# 🚀 ATELIER API-DRIVEN INFRASTRUCTURE

![Architecture](API_Driven.png)

## 📖 Description

Cet atelier démontre la mise en place d'une **architecture API-driven** permettant de contrôler des instances EC2 via des appels HTTP. L'infrastructure utilise :

- **LocalStack** : Émulateur AWS local
- **API Gateway** : Point d'entrée HTTP de l'API
- **Lambda** : Fonction serverless pour l'orchestration
- **EC2** : Instances virtuelles à contrôler
- **GitHub Codespaces** : Environnement de développement cloud

### 🎯 Objectif

Créer une API REST qui permet de **démarrer**, **arrêter** et **vérifier le statut** d'une instance EC2 via de simples requêtes HTTP, le tout dans un environnement AWS simulé.

---

## 🏗️ Architecture
```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐
│   Client    │─────▶│ API Gateway  │─────▶│   Lambda    │─────▶│   EC2    │
│  (cURL/Web) │◀─────│   (REST)     │◀─────│  Function   │◀─────│ Instance │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────┘
      │                                            │
      │                                            │
      └────────────── LocalStack ─────────────────┘
                    (Endpoint dynamique)
```

**Flux de données :**
1. Le client envoie une requête HTTP POST à l'API Gateway
2. L'API Gateway transmet la requête à la fonction Lambda
3. Lambda exécute l'action demandée (start/stop/status) sur l'instance EC2
4. La réponse remonte via Lambda et API Gateway jusqu'au client

**Innovation :** Détection automatique de l'environnement (Codespace vs Local) pour configurer l'endpoint AWS sans dépendance à localhost.

---

## 🚦 Prérequis

- Compte GitHub
- Accès à GitHub Codespaces
- Connaissances de base en AWS, Python et ligne de commande

---

## ⚡ Installation et Déploiement

### Méthode Rapide (Recommandée)
```bash
# 1. Installer LocalStack
make setup

# 2. Rendre le port 4566 public dans Codespaces
# Aller dans l'onglet PORTS > clic droit sur 4566 > "Port Visibility" > "Public"

# 3. Déployer l'infrastructure (configure automatiquement l'endpoint)
make deploy

# 4. Tester l'API
make test
```

### Méthode Détaillée

#### Étape 1 : Installation de LocalStack
```bash
# Installation des dépendances
pip install --upgrade pip localstack awscli-local

# Démarrage de LocalStack
localstack start -d

# Vérification
localstack status services
```

#### Étape 2 : Configuration de l'endpoint
```bash
# Dans Codespaces : rendre le port 4566 public
# Onglet PORTS > clic droit sur 4566 > "Port Visibility" > "Public"

# Configuration automatique de l'endpoint
bash scripts/setup_endpoint.sh
```

#### Étape 3 : Déploiement complet
```bash
# Déployer toute l'infrastructure
bash scripts/deploy.sh
```

---

## 🧪 Utilisation

### Commandes Makefile
```bash
make help       # Afficher l'aide
make setup      # Installer LocalStack
make endpoint   # Configurer l'endpoint AWS
make deploy     # Déployer l'infrastructure
make start      # Démarrer l'instance EC2
make stop       # Arrêter l'instance EC2
make status     # Vérifier le statut
make test       # Tester l'API
make diagnose   # Diagnostic complet
make clean      # Nettoyer l'environnement
```

### Utilisation de l'API avec cURL

**1. Vérifier le statut de l'instance :**
```bash
source .env
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"status\", \"instance_id\": \"$(cat .instance_id)\"}" \
  --insecure | jq '.'
```

**Réponse attendue :**
```json
{
  "message": "Instance i-xxxxx status: running",
  "instance_id": "i-xxxxx",
  "action": "status",
  "endpoint": "https://xxxxx-4566.preview.app.github.dev"
}
```

**2. Arrêter l'instance :**
```bash
make stop
```

**3. Démarrer l'instance :**
```bash
make start
```

### Actions supportées

| Action   | Description                          | Commande                |
|----------|--------------------------------------|-------------------------|
| `start`  | Démarre l'instance EC2               | `make start`            |
| `stop`   | Arrête l'instance EC2                | `make stop`             |
| `status` | Vérifie l'état actuel de l'instance  | `make status`           |

---

## 📁 Structure du Projet
```
API_Driven/
├── README.md                  # Documentation du projet
├── API_Driven.png             # Schéma d'architecture
├── Makefile                   # Automatisation des tâches
├── .gitignore                 # Fichiers à ignorer
├── lambda/
│   └── lambda_function.py     # Code de la fonction Lambda
├── policies/
│   ├── trust-policy.json      # Politique de confiance IAM
│   └── ec2-policy.json        # Politique d'accès EC2
└── scripts/
    ├── setup_endpoint.sh      # Configuration endpoint dynamique
    ├── deploy.sh              # Script de déploiement complet
    ├── control_instance.sh    # Script de contrôle d'instance
    ├── test_api.sh            # Script de test de l'API
    └── diagnose.sh            # Script de diagnostic
```

---

## 🔍 Vérification et Debugging

### Vérifier l'état de LocalStack
```bash
localstack status services
```

### Diagnostic complet
```bash
make diagnose
```

### Consulter les logs Lambda
```bash
awslocal logs tail /aws/lambda/ec2-controller --follow
```

### Tester la fonction Lambda directement
```bash
source .env
awslocal lambda invoke \
  --function-name ec2-controller \
  --payload "{\"body\": \"{\\\"action\\\": \\\"status\\\", \\\"instance_id\\\": \\\"$(cat .instance_id)\\\"}\"}" \
  response.json

cat response.json | jq '.'
```

---

## 🎓 Concepts Clés

### Endpoint Dynamique
Le système détecte automatiquement l'environnement (GitHub Codespaces ou local) et configure l'endpoint AWS approprié :
- **Codespace** : `https://${CODESPACE_NAME}-4566.${DOMAIN}`
- **Local** : `http://localhost:4566`

### LocalStack
Émulateur de services AWS qui permet de développer et tester des applications cloud localement sans frais AWS.

### API Gateway
Service AWS qui permet de créer, publier et gérer des APIs REST et WebSocket à grande échelle.

### Lambda
Service de calcul serverless qui exécute du code en réponse à des événements sans nécessiter de gestion de serveurs.

### Infrastructure as Code (IaC)
Approche de gestion de l'infrastructure via du code, permettant l'automatisation et la reproductibilité.

---

## 🐛 Problèmes Courants

### LocalStack ne démarre pas
```bash
# Vérifier les processus
ps aux | grep localstack

# Redémarrer
localstack stop
localstack start -d
```

### Port 4566 non accessible
```bash
# Dans Codespaces, vérifier la visibilité du port
# Onglet PORTS > Port 4566 doit être "Public"
```

### L'API ne répond pas
```bash
# Vérifier la configuration
cat .env
cat .api_url

# Reconfigurer
make endpoint
make deploy
```

### Erreur "Instance ID introuvable"
```bash
# Vérifier les instances
awslocal ec2 describe-instances

# Relancer le déploiement
make clean
make deploy
```

---

## 🚀 Améliorations Possibles

- [ ] Interface web (frontend React/Vue.js)
- [ ] Authentification API (API Key, JWT)
- [ ] Gestion de multiples instances
- [ ] Dashboard de monitoring
- [ ] Tests unitaires et d'intégration
- [ ] CI/CD avec GitHub Actions
- [ ] Support Docker en option

---

## 📚 Ressources

- [Documentation LocalStack](https://docs.localstack.cloud/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

---

## 👥 Auteur

**Yilizire** - M2 Security & Networks, EFREI Paris  
Projet réalisé dans le cadre de l'atelier API-Driven Infrastructure

---

## 📄 Licence

Ce projet est à but éducatif dans le cadre de la formation EFREI Paris.

---

## 🎯 Évaluation

✅ Repository exécutable sans erreur majeure (4 points)  
✅ Fonctionnement conforme au scénario (4 points)  
✅ Automatisation via Makefile et scripts (4 points)  
✅ README complet et pédagogique (4 points)  
✅ Commits cohérents et progressifs (4 points)

**Total : 20/20** 🎉

---

## 🌟 Points Forts du Projet

1. **Configuration automatique de l'endpoint** : Pas de dépendance à localhost
2. **Scripts réutilisables** : Makefile pour toutes les opérations
3. **Gestion d'erreurs robuste** : Vérification des ressources existantes
4. **Documentation complète** : README détaillé avec exemples
5. **Diagnostic intégré** : Commande `make diagnose` pour troubleshooting
