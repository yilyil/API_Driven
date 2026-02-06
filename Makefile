.PHONY: help setup endpoint deploy start stop status test diagnose clean

help:
	@echo "🚀 API-Driven Infrastructure - Commandes disponibles"
	@echo ""
	@echo "  make setup      - Installer et démarrer LocalStack"
	@echo "  make deploy     - Déployer l'infrastructure complète"
	@echo "  make start      - Démarrer l'instance EC2"
	@echo "  make stop       - Arrêter l'instance EC2"
	@echo "  make status     - Vérifier le statut de l'instance"
	@echo "  make test       - Tester l'API (4 tests automatiques)"
	@echo "  make diagnose   - Diagnostic complet"
	@echo "  make clean      - Tout supprimer et repartir de zéro"
	@echo ""

setup:
	@echo "📦 Installation de LocalStack..."
	@pip install --quiet --upgrade pip localstack awscli-local
	@localstack start -d
	@sleep 10
	@localstack status services
	@echo "✅ LocalStack démarré"
	@echo ""
	@echo "⚠️  IMPORTANT (Codespaces uniquement):"
	@echo "    Rendez le port 4566 PUBLIC dans l'onglet PORTS"

deploy:
	@echo "🔨 Déploiement de l'infrastructure..."
	@bash scripts/setup_endpoint.sh
	@bash scripts/deploy.sh

start:
	@bash scripts/control_instance.sh start

stop:
	@bash scripts/control_instance.sh stop

status:
	@bash scripts/control_instance.sh status

test:
	@bash scripts/test_api.sh

diagnose:
	@bash scripts/diagnose.sh

clean:
	@echo "🧹 Nettoyage complet..."
	@awslocal lambda delete-function --function-name ec2-controller 2>/dev/null || true
	@awslocal ec2 terminate-instances --instance-ids $$(cat .instance_id 2>/dev/null) 2>/dev/null || true
	@rm -f .instance_id .api_id .api_url .aws_endpoint .env my-key.pem lambda/*.zip 2>/dev/null || true
	@localstack stop 2>/dev/null || true
	@echo "✅ Environnement nettoyé"
