# Copyright 2024 Chris Farris <chris@primeharbor.com>
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

variable "stack_set_name" {
  type = string
}

variable "stack_set_description" {
  type = string
}

variable "stack_set_template_body" {
  type = string
}

variable "stack_set_template_url" {
  type = string
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "retain_stack" {
  default = true
}

variable "region" {
  default = "us-east-1"
}

locals {
  stack_set_template_body = var.stack_set_template_url == null ? var.stack_set_template_body : null
  stack_set_template_url  = var.stack_set_template_url != null ? var.stack_set_template_url : null
}