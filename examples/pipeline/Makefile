# Copyright 2023 Chris Farris <chris@primeharbor.com>
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

first-deploy: tf-init tf-execute

destroy: tf-init tf-destroy

update: tf-init tf-execute

#
# Terraform
#
tf-init:
	terraform init -backend-config=$(env).tfbackend -reconfigure

tf-plan:
	terraform plan -out=$(env)-terraform.tfplan -no-color -var-file="$(env).tfvars"

tf-apply:
	terraform apply $(env)-terraform.tfplan
	@rm $(env)-terraform.tfplan
	terraform output -json > output-$(env).json
	@aws s3 cp output-$(env).json s3://$(bucket)/output-$(env).json

tf-destroy:
	terraform destroy --auto-approve

tf-refresh:
	terraform apply -refresh-only

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

clean:
	rm -rf .terraform .terraform.lock.hcl outputs*.json *.tfplan

