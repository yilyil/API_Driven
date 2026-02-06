.PHONY: help setup endpoint deploy start stop status test diagnose clean

help:
	@echo "🚀 API-Driven Infrastructure - Commandes disponibles:"
	@echo ""
	@echo "  make setup      - Installer LocalStack"
	@echo "  make endpoint   - Configurer l'endpoint AWS (Codespace/Local)"
	@echo "  make deploy     - Déployer l'infrastructure complète"
	@echo "  make start      - Démarrer l'instance EC2"
	@echo "  make stop       - Arrêter l'instance EC2"
	@echo "  make status     - Vérifier le statut de l'instance"
	@echo "  make test       - Tester l'API"
	@echo "  make diagnose   - Diagnostic complet"
	@echo "  make clean      - Nettoyer l'environnement"
	@echo ""

setup:
	@echo "📦 Installation de LocalStack..."
	@pip install --quiet --upgrade pip localstack awscli-local
	@localstack start -d
	@sleep 10
	@localstack status services
	@echo "✅ LocalStack démarré"

endpoint:
	@echo "🔧 Configuration de l'endpoint..."
	@bash scripts/setup_endpoint.sh
	@echo "✅ Endpoint configuré"

deploy: endpoint
	@echo "🔨 Déploiement de l'infrastructure..."
	@bash scripts/deploy.sh
	@echo "✅ Infrastructure déployée"

start:
	@echo "▶️  Démarrage de l'instance EC2..."
	@bash scripts/control_instance.sh start

stop:
	@echo "⏹️  Arrêt de l'instance EC2..."
	@bash scripts/control_instance.sh stop

status:
	@echo "ℹ️  Vérification du statut..."
	@bash scripts/control_instance.sh status

test:
	@echo "🧪 Test de l'API..."
	@bash scripts/test_api.sh

diagnose:
	@echo "🔍 Diagnostic de l'infrastructure..."
	@bash scripts/diagnose.sh

clean:
	@echo "🧹 Nettoyage de l'environnement..."
	@awslocal lambda delete-function --function-name ec2-controller 2>/dev/null || true
	@awslocal ec2 terminate-instances --instance-ids $$(cat .instance_id 2>/dev/null) 2>/dev/null || true
	@localstack stop
	@rm -f .instance_id .api_id .api_url .aws_endpoint .env my-key.pem lambda/*.zip
	@echo "✅ Environnement nettoyé"
