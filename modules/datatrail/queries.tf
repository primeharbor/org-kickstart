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


resource "aws_athena_named_query" "bucket_activity_report" {
  provider    = aws.security-account
  name        = "bucket_activity_report"
  description = "Number of events on a per-bucket basis. Use this to track activity and buckets to exclude for cost"
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT
        r.arn AS s3_bucket_name,
        COUNT(*) AS record_count
    FROM ${aws_glue_catalog_database.datatrail.name}
    CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
    AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
    GROUP BY r.arn
    ORDER BY record_count DESC;
EOQ
}

resource "aws_athena_named_query" "anonymous_activity" {
  provider    = aws.security-account
  name        = "anonymous_activity_report_1day"
  description = "List of Buckets that are getting anonymous access requests"
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT eventname,
      r.arn AS s3_bucket_name,
      recipientaccountid AS AWSAccount,
      count(*) AS TotalEvents
    FROM ${aws_glue_catalog_database.datatrail.name}
      CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
      AND useridentity.accountid = 'anonymous'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
    GROUP BY r.arn, eventname, recipientaccountid;
EOQ
}

resource "aws_athena_named_query" "bucket_usage" {
  provider    = aws.security-account
  name        = "bucket_usage"
  description = "List of Objects being requested from a specific Bucket."
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT eventName,
      errorcode,
      sourceipaddress,
      errormessage,
      json_extract_scalar(requestparameters, '$.bucketName') AS bucket_name,
      json_extract_scalar(requestparameters, '$.key') AS object_key,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END AS principal
    FROM ${aws_glue_catalog_database.datatrail.name}
    WHERE json_extract_scalar(requestparameters, '$.bucketName') = 'BUCKET_NAME_CHANGEME'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
    ORDER BY object_key
EOQ
}


resource "aws_athena_named_query" "all_usage" {
  provider    = aws.security-account
  name        = "all_usage"
  description = "In-depth report of all principals accessing each Bucket."
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT eventname,
      r.arn AS s3_bucket_name,
      recipientaccountid AS AWSAccount,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END AS principal,
      COUNT(*) AS TotalEvents
    FROM ${aws_glue_catalog_database.datatrail.name}
      CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
    GROUP BY r.arn,
      eventname,
      recipientaccountid,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END
    ORDER BY TotalEvents DESC
EOQ
}


resource "aws_athena_named_query" "external_accounts" {
  provider    = aws.security-account
  name        = "external_accounts"
  description = "Report on all AWS Accounts that are accessing each bucket"
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT r.arn AS s3_bucket_name,
      useridentity.accountid,
      COUNT(*) AS record_count
    FROM datatrail
      CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
      AND useridentity.accountid IS NOT null
    GROUP BY r.arn,
      useridentity.accountid
    ORDER BY record_count DESC;
EOQ
}

resource "aws_athena_named_query" "data_access_errors" {
  provider    = aws.security-account
  name        = "data_access_errors"
  description = "Report on all Errors accessing S3 Buckets in the org"
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT eventname,
      r.arn AS s3_bucket_name,
      recipientaccountid AS AWSAccount,
      errormessage,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END AS principal,
      COUNT(*) AS TotalEvents
    FROM datatrail
      CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
      AND errorcode = 'AccessDenied'
    GROUP BY r.arn,
      eventname,
      recipientaccountid,
      errormessage,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END
    ORDER BY TotalEvents DESC
EOQ
}

resource "aws_athena_named_query" "data_access_errors_explicit_deny" {
  provider    = aws.security-account
  name        = "data_access_errors_explicit_deny"
  description = "Report on all Errors accessing S3 Buckets in the org where the error message contains 'explict deny'"
  workgroup   = aws_athena_workgroup.datatrail.id
  database    = aws_glue_catalog_database.datatrail.name
  query       = <<EOQ
    SELECT eventname,
      r.arn AS s3_bucket_name,
      recipientaccountid AS AWSAccount,
      errormessage,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END AS principal,
      COUNT(*) AS TotalEvents
    FROM datatrail
      CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
      AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
      AND errorcode = 'AccessDenied'
      AND errormessage LIKE '%explicit% den%'
    GROUP BY r.arn,
      eventname,
      recipientaccountid,
      errormessage,
      CASE
        WHEN useridentity.arn IS NOT null then useridentity.arn
        WHEN useridentity.accountid = 'anonymous' then 'anonymous'
        ELSE useridentity.invokedby
      END
    ORDER BY TotalEvents DESC
EOQ
}