.PHONY: help pre-commit fmt

# Environment configurations
STAGING_PROFILE := staging-piksel
STAGING_DIR := staging

DEV_PROFILE := dev-piksel
DEV_DIR := dev

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

pre-commit: ## Run pre-commit hooks on all files
	pre-commit run -a

fmt: ## Format all Terraform files recursively
	terraform fmt -recursive

# ============================================
# STAGING
# ============================================
init-staging: ## Initialize Terraform for staging environment
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) init

validate-staging: ## Validate Terraform configuration for staging
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) validate

plan-staging: ## Show Terraform plan for staging
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) plan

apply-staging: ## Apply Terraform changes to staging
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) apply

apply-staging-auto: ## Apply Terraform changes to staging without confirmation
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) apply -auto-approve

backup-staging: ## Run backup script for staging
	cd ./$(STAGING_DIR) && bash backup.sh run && cd ..

output-staging: ## Show Terraform outputs for staging
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) output

show-staging: ## Show current Terraform state for staging
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) show


# ============================================
# DEV
# ============================================
init-dev: ## Initialize Terraform for dev environment
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) init

validate-dev: ## Validate Terraform configuration for dev
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) validate

plan-dev: ## Show Terraform plan for dev
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) plan

apply-dev: ## Apply Terraform changes to dev
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) apply

backup-dev: ## Run backup script for dev
	cd ./$(DEV_DIR) && bash backup.sh run && cd ..

output-dev: ## Show Terraform outputs for dev
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) output

show-dev: ## Show current Terraform state for dev
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) show
