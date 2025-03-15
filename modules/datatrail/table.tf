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
      name = "eventversion"
      type = "string"
    }

    columns {
      name = "useridentity"
      type = "struct<type:string,principalId:string,arn:string,accountId:string,invokedBy:string,accessKeyId:string,userName:string,sessionContext:struct<attributes:struct<mfaAuthenticated:string,creationDate:string>,sessionIssuer:struct<type:string,principalId:string,arn:string,accountId:string,username:string>,ec2RoleDelivery:string,webIdFederationData:struct<federatedProvider:string,attributes:map<string,string>>>>"
    }

    columns {
      name = "eventtime"
      type = "string"
    }

    columns {
      name = "eventsource"
      type = "string"
    }

    columns {
      name = "eventname"
      type = "string"
    }

    columns {
      name = "awsregion"
      type = "string"
    }

    columns {
      name = "sourceipaddress"
      type = "string"
    }

    columns {
      name = "useragent"
      type = "string"
    }

    columns {
      name = "errorcode"
      type = "string"
    }

    columns {
      name = "errormessage"
      type = "string"
    }

    columns {
      name = "requestparameters"
      type = "string"
    }

    columns {
      name = "responseelements"
      type = "string"
    }

    columns {
      name = "additionaleventdata"
      type = "string"
    }

    columns {
      name = "requestid"
      type = "string"
    }

    columns {
      name = "eventid"
      type = "string"
    }

    columns {
      name = "resources"
      type = "array<struct<arn:string,accountid:string,type:string>>"
    }

    columns {
      name = "eventtype"
      type = "string"
    }

    columns {
      name = "apiversion"
      type = "string"
    }

    columns {
      name = "readonly"
      type = "boolean"
    }

    columns {
      name = "recipientaccountid"
      type = "string"
    }

    columns {
      name = "serviceeventdetails"
      type = "string"
    }

    columns {
      name = "sharedeventid"
      type = "string"
    }

    columns {
      name = "vpcendpointid"
      type = "string"
    }
  }
}
