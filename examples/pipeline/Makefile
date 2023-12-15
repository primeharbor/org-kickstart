# Copyright 2022 - Chris Farris (chrisf@primeharbor.com) - All Rights Reserved
#
# NOTE: This code artifact is NOT licensed under an OpenSource license. You have access to it via an existing
# arrangement for training purposes only, but it may not be distributed further without violating Copyright Law.

ifndef env
$(error env is not set)
endif

include $(env).tfbackend

first-deploy: tf-init tf-execute

destroy: tf-init tf-destroy

update: tf-init tf-execute

#
# Terraform
#
tf-init:
	terraform init -backend-config=$(env).tfbackend -reconfigure

tf-update:
	terraform get -update

tf-plan:
	terraform plan -out=$(env)-terraform.tfplan -no-color -var-file="$(env).tfvars"

tf-apply:
	terraform apply $(env)-terraform.tfplan
	@rm $(env)-terraform.tfplan
	terraform output -json > output-$(env).json
	@aws s3 cp output-$(env).json s3://$(bucket)/output-$(env).json

tf-destroy:
	terraform destroy --auto-approve -var-file="$(env).tfvars"

tf-plan-destroy:
	terraform plan --destroy -var-file="$(env).tfvars" -out=$(env)-terraform.tfplan

tf-refresh:
	terraform apply -refresh-only -var-file="$(env).tfvars"

tf-force:
	terraform apply -auto-approve
	terraform output -json > output-$(env).json
	@aws s3 cp output-$(env).json s3://$(bucket)/output-$(env).json

tf-output:
	terraform output -json > output-$(env).json

tf-show:
	@terraform show $(env)-terraform.tfplan -no-color

tf-plan-save:
	@aws s3 cp $(env)-terraform.tfplan s3://$(bucket)/$(env)-terraform.tfplan

tf-plan-fetch:
	@aws s3 cp s3://$(bucket)/$(env)-terraform.tfplan $(env)-terraform.tfplan
	@aws s3 rm s3://$(bucket)/$(env)-terraform.tfplan

tf-execute: tf-plan tf-apply

download-state:
	@aws s3 cp s3://$(bucket)/$(key) $(env).tfstate

clean:
	rm -rf .terraform .terraform.lock.hcl outputs*.json *.tfplan

