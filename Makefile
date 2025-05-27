# MoM (Mule of Mules) Makefile

# Default target
.PHONY: help
help: ## Show this help message
	@echo "MoM (Mule of Mules) - Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Setup and installation
.PHONY: install
install: ## Install dependencies
	bundle install

.PHONY: setup
setup: install generate-grpc db-setup ## Complete project setup

.PHONY: db-setup
db-setup: ## Setup database
	bundle exec rails db:create
	bundle exec rails db:migrate

.PHONY: db-reset
db-reset: ## Reset database
	bundle exec rails db:drop db:create db:migrate

# gRPC code generation
.PHONY: generate-grpc
generate-grpc: ## Generate gRPC code from protobuf
	bundle exec grpc_tools_ruby_protoc -I lib/proto --ruby_out=lib/proto --grpc_out=lib/proto lib/proto/mule.proto

# Development
.PHONY: server
server: ## Start Rails server
	bundle exec rails server

.PHONY: console
console: ## Start Rails console
	bundle exec rails console

.PHONY: routes
routes: ## Show all routes
	bundle exec rails routes

# Testing
.PHONY: test
test: ## Run all tests
	bundle exec rspec

.PHONY: test-watch
test-watch: ## Run tests in watch mode
	bundle exec guard

# Code quality
.PHONY: lint
lint: ## Run linter
	bundle exec rubocop

.PHONY: lint-fix
lint-fix: ## Fix linting issues
	bundle exec rubocop -a

.PHONY: security
security: ## Run security checks
	bundle exec brakeman

# Deployment
.PHONY: precompile
precompile: ## Precompile assets
	RAILS_ENV=production bundle exec rails assets:precompile

.PHONY: production-setup
production-setup: ## Setup for production
	RAILS_ENV=production bundle exec rails db:migrate

# Docker
.PHONY: docker-build
docker-build: ## Build Docker image
	docker build -t mom:latest .

.PHONY: docker-run
docker-run: ## Run Docker container
	docker run -p 3000:3000 -p 50051:50051 --rm mom:latest

.PHONY: docker-up
docker-up: ## Start services with docker-compose
	docker compose up 

.PHONY: docker-down
docker-down: ## Stop services with docker-compose
	docker compose down

.PHONY: docker-logs
docker-logs: ## View docker-compose logs
	docker compose logs -f

.PHONY: docker-start
docker-start: docker-build docker-up ## Build and run Docker container in one step

# Cleanup
.PHONY: clean
clean: ## Clean temporary files
	bundle exec rails tmp:clear
	bundle exec rails log:clear

.PHONY: clean-all
clean-all: clean ## Clean everything including generated files
	rm -rf lib/proto/*_pb.rb
	rm -rf tmp/
	rm -rf log/*.log

# Development helpers
.PHONY: grpc-test
grpc-test: ## Test gRPC server connectivity
	@echo "Testing gRPC server on localhost:50051..."
	@grpcurl -plaintext localhost:50051 list || echo "gRPC server not responding"

.PHONY: logs
logs: ## Tail application logs
	tail -f log/development.log

.PHONY: ps
ps: ## Show running processes
	ps aux | grep -E "(rails|puma|grpc)" | grep -v grep

# Environment
.PHONY: env-check
env-check: ## Check environment setup
	@echo "Checking Ruby version..."
	@ruby --version
	@echo "Checking Rails version..."
	@bundle exec rails --version
	@echo "Checking database connection..."
	@bundle exec rails runner "puts ActiveRecord::Base.connection.adapter_name"
