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
  provider  = aws.security-account
  name      = "bucket_activity_report"
  workgroup = aws_athena_workgroup.datatrail.id
  database  = aws_glue_catalog_database.datatrail.name
  query     = <<EOQ
    SELECT
        r.arn AS s3_bucket_name,
        COUNT(*) AS record_count
    FROM datatrail
    CROSS JOIN UNNEST(resources) AS t (r)
    WHERE r.type = 'AWS::S3::Bucket'
    AND from_iso8601_timestamp(eventtime) >= now() - interval '1' day
    GROUP BY r.arn
    ORDER BY record_count DESC;
EOQ
}