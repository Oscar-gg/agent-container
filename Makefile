COMPOSE_FILE := docker-compose.yml
SERVICE      := agent

export UID := $(shell id -u)
export GID := $(shell id -g)

.PHONY: start stop start-dangerously start-telegram start-telegram-dangerously build enter

build:
	docker compose -f $(COMPOSE_FILE) build $(SERVICE)

stop:
	docker compose -f $(COMPOSE_FILE) down

enter:
	docker compose -f $(COMPOSE_FILE) exec $(SERVICE) bash

start:
	docker compose -f $(COMPOSE_FILE) run --rm $(SERVICE) claude

start-telegram:
	docker compose -f $(COMPOSE_FILE) run --rm \
		$(SERVICE) claude --channels plugin:telegram@claude-plugins-official

start-telegram-dangerously:
	docker compose -f $(COMPOSE_FILE) run --rm \
		-e CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=1 \
		$(SERVICE) claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official

start-dangerously:
	docker compose -f $(COMPOSE_FILE) run --rm \
		-e CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=1 \
		$(SERVICE) claude --dangerously-skip-permissions
