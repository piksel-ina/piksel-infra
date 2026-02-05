.PHONY: apply-staging fmt

pre-commit:
	pre-commit run -a

fmt:
	terraform fmt -recursive

apply-staging:
	terraform -chdir=staging apply

backup-staging:
	cd ./staging && bash backup.sh run && cd ..
