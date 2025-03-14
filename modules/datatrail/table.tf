# Copyright 2025 Chris Farris <chris@primeharbor.com>
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

# Athena Table for CloudTrail Logs
resource "aws_glue_catalog_table" "datatrail" {
  provider      = aws.security-account
  name          = "datatrail"
  database_name = aws_glue_catalog_database.datatrail.name
  description   = "CloudTrail Data Events from ${var.bucket_name}"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "cloudtrail"
    "EXTERNAL"       = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${var.bucket_name}/AWSLogs/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      #   serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "eventVersion"
      type = "string"
    }

    columns {
      name = "userIdentity"
      type = "struct<type:string,principalId:string,arn:string,accountId:string,invokedBy:string,accessKeyId:string,userName:string,sessionContext:struct<attributes:struct<mfaAuthenticated:string,creationDate:string>,sessionIssuer:struct<type:string,principalId:string,arn:string,accountId:string,username:string>,ec2RoleDelivery:string,webIdFederationData:struct<federatedProvider:string,attributes:map<string,string>>>>"
    }

    columns {
      name = "eventTime"
      type = "string"
    }

    columns {
      name = "eventSource"
      type = "string"
    }

    columns {
      name = "eventName"
      type = "string"
    }

    columns {
      name = "awsRegion"
      type = "string"
    }

    columns {
      name = "sourceIpAddress"
      type = "string"
    }

    columns {
      name = "userAgent"
      type = "string"
    }

    columns {
      name = "errorCode"
      type = "string"
    }

    columns {
      name = "errorMessage"
      type = "string"
    }

    columns {
      name = "requestParameters"
      type = "string"
    }

    columns {
      name = "responseElements"
      type = "string"
    }

    columns {
      name = "additionalEventData"
      type = "string"
    }

    columns {
      name = "requestId"
      type = "string"
    }

    columns {
      name = "eventId"
      type = "string"
    }

    columns {
      name = "resources"
      type = "array<struct<arn:string,accountid:string,type:string>>"
    }

    columns {
      name = "eventType"
      type = "string"
    }

    columns {
      name = "apiVersion"
      type = "string"
    }

    columns {
      name = "readOnly"
      type = "boolean"
    }

    columns {
      name = "recipientAccountId"
      type = "string"
    }

    columns {
      name = "serviceEventDetails"
      type = "string"
    }

    columns {
      name = "sharedEventID"
      type = "string"
    }

    columns {
      name = "vpcEndpointId"
      type = "string"
    }
  }
}
