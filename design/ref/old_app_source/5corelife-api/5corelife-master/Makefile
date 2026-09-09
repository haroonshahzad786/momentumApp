VENV := venv
API_SERVICE := django
DOCKER_COMMAND := docker-compose -p 5corelife -f $(shell pwd)/docker-compose.yml

setup: ## Create virtual environment if not exists and install requirements
	test -d $(VENV) || virtualenv -p python3.8 $(VENV)
	@source ./$(VENV)/bin/activate && pip install -r requirements/local.txt

build: ## Build project image
	$(DOCKER_COMMAND) build --no-cache --pull

start: ## Start project containers defined in docker-compose
	$(DOCKER_COMMAND) up -d --build

stop: ## Stop project containers defined in docker-compose
	$(DOCKER_COMMAND) stop

bash: ## Open a bash shell in project's main container
	$(DOCKER_COMMAND) exec -e DJANGO_SETTINGS_MODULE=config.settings.local $(API_SERVICE) bash

initialize-db: ## Create data necessary after to run the project
	$(DOCKER_COMMAND) exec $(API_SERVICE) python manage.py initialize_db

superuser: ## Create Superuser
	$(DOCKER_COMMAND) exec $(API_SERVICE) python manage.py createsuperuser

show-migrations: ## Display all migrations
	$(DOCKER_COMMAND) exec -T $(API_SERVICE) python manage.py showmigrations

test: ## Run test suite in project's main container
	$(DOCKER_COMMAND) exec -e DJANGO_SETTINGS_MODULE=config.settings.test $(API_SERVICE) coverage run -m pytest

test-html: ## Generate report
	$(DOCKER_COMMAND) exec -e DJANGO_SETTINGS_MODULE=config.settings.test $(API_SERVICE) coverage html

linter: ## Check/Enforce Python Code-Style
	$(DOCKER_COMMAND) exec -T $(API_SERVICE) flake8

formatter: ## Check/Enforce Python Code-Style
	$(DOCKER_COMMAND) exec -T $(API_SERVICE) black --check .

view-logs: ## Display interactive logs of all project containers
	$(DOCKER_COMMAND) logs -f

## Run formatter, linter and test
all: formatter linter test
