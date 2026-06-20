# Copyright 2023-2026 Chris Farris <chris@primeharbor.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifndef env
$(error env is not set)
endif

include $(env).tfbackend

export DEPLOY_BUCKET=$(bucket)

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

#
# Account Configurator (pht-account-configurator submodule)
#
# `make env=<env> account-configurator` does the needful so a subsequent
# `make env=<env> tf-execute` deploys the configurator stack via Terraform:
#   1. Makes sure the submodule is checked out
#   2. Seeds <env>-account-config.yaml from the submodule sample if it doesn't exist
#   3. Packages the CloudFormation template into the org-kickstart state bucket
#   4. Points account_configurator.template in <env>.tfvars at the freshly packaged template
#
CONFIGURATOR_DIR     = pht-account-configurator
CONFIGURATOR_PREFIX  = pht-account-configurator
CONFIGURATOR_CONFIG  = $(env)-account-config.yaml
# `bucket` is read from $(env).tfbackend where it is wrapped in quotes (bucket="..."); strip them
# so the value is safe to embed in a URL and inside the single-quoted sed below.
CONFIGURATOR_BUCKET  := $(subst ",,$(bucket))
# Evaluated once (:=) so the packaged template name and the URL we write to tfvars match.
CONFIGURATOR_VERSION := $(shell date +%Y%m%d-%H%M)
CONFIGURATOR_TEMPLATE_URL = https://s3.amazonaws.com/$(CONFIGURATOR_BUCKET)/$(CONFIGURATOR_PREFIX)/AccountFactory-Template-Transformed-$(CONFIGURATOR_VERSION).yaml

.PHONY: account-configurator
account-configurator:
	@if [ ! -f $(CONFIGURATOR_DIR)/Makefile ]; then \
		git submodule update --init $(CONFIGURATOR_DIR) 2>/dev/null || { \
			echo "ERROR: the $(CONFIGURATOR_DIR) submodule is not set up. Add it once with:" ; \
			echo "    git submodule add git@github.com:primeharbor/pht-account-configurator.git $(CONFIGURATOR_DIR)" ; \
			echo "    git commit -m 'Add pht-account-configurator submodule'" ; \
			exit 1 ; \
		} ; \
	fi
	@if [ ! -f $(CONFIGURATOR_CONFIG) ]; then \
		cp $(CONFIGURATOR_DIR)/account-factory-config.yaml $(CONFIGURATOR_CONFIG) ; \
		echo ">> Seeded $(CONFIGURATOR_CONFIG) from the submodule sample - review it before applying" ; \
	fi
	cd $(CONFIGURATOR_DIR) && DEPLOY_BUCKET=$(CONFIGURATOR_BUCKET) version=$(CONFIGURATOR_VERSION) $(MAKE) package
	@python3 scripts/update_account_configurator_tfvars.py $(env).tfvars "$(CONFIGURATOR_TEMPLATE_URL)" "$(CONFIGURATOR_CONFIG)"
	@echo ">> Set account_configurator.template -> $(CONFIGURATOR_TEMPLATE_URL)"
	@echo ">> Set account_configurator.account_factory_config_file -> $(CONFIGURATOR_CONFIG)"
	@echo ">> Now run: make env=$(env) tf-plan && make env=$(env) tf-apply"

# .PHONY so the target always runs even if a granted/ directory is later created
# alongside it; otherwise make would see the directory and report "granted is up to date".
.PHONY: granted
granted:
	@mkdir -p granted
	@./scripts/generate_granted_config.sh output-$(env).json > granted/aws-config

checkov:
	@terraform show -json $(env)-terraform.tfplan | jq > $(env)-tfplan.json
	checkov -s -f $(env)-tfplan.json --repo-root-for-plan-enrichment . --quiet --compact \
		--skip-check CKV2_AWS_3,CKV2_AWS_62,CKV_AWS_144,CKV_AWS_274,CKV_AWS_124,CKV2_AWS_61,CKV_AWS_18
