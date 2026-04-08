.PHONY: help pre-commit fmt

# Colors
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

# Cluster defaults
EKS_VERSION   ?= 1.32
ARCHITECTURE  ?= x86_64
AWS_REGION    ?= ap-southeast-3

# Environment configurations
STAGING_PROFILE := staging-piksel
STAGING_DIR     := staging
CLUSTER_NAME_STAGING   ?= piksel-staging
STAGING_CONTEXT        := piksel-staging
AWS_PROFILE_STAGING    := $(STAGING_PROFILE)

DEV_PROFILE := dev-piksel
DEV_DIR     := dev

# Directories
SCRIPTS_DIR := scripts

# Normalized Variables
_EKS_VERSION         := $(strip $(EKS_VERSION))
_ARCHITECTURE        := $(strip $(ARCHITECTURE))
_AWS_REGION          := $(strip $(AWS_REGION))
_AWS_PROFILE_STAGING := $(strip $(AWS_PROFILE_STAGING))
_CLUSTER_NAME_STAGING := $(strip $(CLUSTER_NAME_STAGING))

export

help: ## Show this help message
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '\033[1mGeneral\033[0m'
	@grep -E '^(pre-commit|fmt):.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-22s\033[0m %s\n",$$1,$$2}'
	@echo ''
	@echo '\033[1mStaging\033[0m'
	@grep -E '^[a-z]+-staging:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-22s\033[0m %s\n",$$1,$$2}'
	@echo ''
	@echo '\033[1mCluster Checks\033[0m'
	@grep -E '^(check-|restart-|scan-)[a-z]+:.*## ' $(MAKEFILE_LIST) | grep -vE -- '-(staging|dev):' | awk -F':.*## ' '{printf "  \033[36m%-22s\033[0m %s\n",$$1,$$2}'
	@echo ''
	@echo '\033[1mDev\033[0m'
	@grep -E '^[a-z]+-dev:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-22s\033[0m %s\n",$$1,$$2}'
	@echo ''

pre-commit: ## Run pre-commit hooks
	fmt

fmt: ## Format Terraform files
	terraform fmt -recursive

# ============================================
# STAGING
# ============================================

init-staging: ## Terraform init
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) init

validate-staging: ## Terraform validate
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) validate

plan-staging: ## Terraform plan
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) plan

apply-staging: ## Terraform apply
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) apply

backup-staging: ## Backup state to S3
	cd ./$(STAGING_DIR) && bash backup.sh run && cd ..

output-staging: ## Terraform output
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) output

show-staging: ## Terraform show
	AWS_PROFILE=$(STAGING_PROFILE) terraform -chdir=$(STAGING_DIR) show

# ============================================
# DEV
# ============================================

init-dev: ## Terraform init
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) init

validate-dev: ## Terraform validate
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) validate

plan-dev: ## Terraform plan
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) plan

apply-dev: ## Terraform apply
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) apply

backup-dev: ## Backup state to S3
	cd ./$(DEV_DIR) && bash backup.sh run && cd ..

output-dev: ## Terraform output
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) output

show-dev: ## Terraform show
	AWS_PROFILE=$(DEV_PROFILE) terraform -chdir=$(DEV_DIR) show

# ============================================
# CLUSTER CHECKS (Staging only)
# ============================================

check-context: ## kubectl context info
	@$(SCRIPTS_DIR)/check-context.sh

check-ami: ## Node AMIs vs AWS recommended
	@$(SCRIPTS_DIR)/check-ami.sh

check-versions: ## Installed vs recommended addon versions
	@$(SCRIPTS_DIR)/check-versions.sh staging

check-health: ## Cluster & pod health
	@$(SCRIPTS_DIR)/check-health.sh staging

check-endpoints: ## Test endpoint connectivity
	@$(SCRIPTS_DIR)/check-endpoints.sh staging

restart-deployments: ## Restart all deployments
	@$(SCRIPTS_DIR)/restart-deployments.sh staging

scan-deprecated: ## Scan deprecated APIs
	@$(SCRIPTS_DIR)/scan-deprecated.sh staging
