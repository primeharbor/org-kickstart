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

variable "payer_email" {}
variable "organization_name" {}

variable "billing_levels" {
  type    = map(any)
  default = {}
}

variable "billing_subscriptions" {
  type    = list(any)
  default = []
}


resource "aws_sns_topic" "billing_alerts" {
  name = "${var.organization_name}-billing-alerts"
}

resource "aws_sns_topic_subscription" "billing_alerts_root_email" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.payer_email
}

resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  for_each            = var.billing_levels
  alarm_name          = "billing_alarm_${each.key}"
  alarm_description   = "Alarm if AWS spending is over ${each.value}"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.value
  evaluation_periods  = 1
  period              = 21600
  statistic           = "Maximum"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]
}

resource "aws_sns_topic_subscription" "billing_alerts" {
  for_each  = toset(var.billing_subscriptions)
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = each.key
}