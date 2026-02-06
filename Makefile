.PHONY: help setup deploy start stop status test diagnose clean urls

help:
	@echo "🚀 API-Driven Infrastructure - Commandes disponibles"
	@echo ""
	@echo "  make setup      - Installer LocalStack et AWS CLI"
	@echo "  make deploy     - Déployer l'infrastructure"
	@echo "  make urls       - Afficher les 3 URLs de contrôle"
	@echo "  make start      - Démarrer l'instance EC2"
	@echo "  make stop       - Arrêter l'instance EC2"
	@echo "  make status     - Vérifier l'état de l'instance"
	@echo "  make test       - Tester l'API (4 tests)"
	@echo "  make diagnose   - Diagnostic complet"
	@echo "  make clean      - Tout supprimer"
	@echo ""

setup:
	@echo "📦 Installation de AWS CLI et LocalStack..."
	@curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	@unzip -q awscliv2.zip
	@sudo ./aws/install --update 2>/dev/null || sudo ./aws/install
	@rm -rf aws awscliv2.zip
	@pip install --quiet --upgrade pip localstack awscli-local
	@localstack start -d
	@sleep 10
	@localstack status services
	@echo "✅ LocalStack démarré"

deploy:
	@bash scripts/setup_endpoint.sh
	@bash scripts/deploy.sh

urls:
	@bash show_urls.sh

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
	@rm -f .instance_id .api_id .api_url .url_* .aws_endpoint .env my-key.pem lambda/*.zip 2>/dev/null || true
	@localstack stop 2>/dev/null || true
	@echo "✅ Environnement nettoyé"
