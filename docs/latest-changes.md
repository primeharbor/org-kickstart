# New Features

* Accounts accept an optional `close_on_deletion` override. Omitted or null values retain the global `default_close_on_deletion` setting; explicit false values override a true global default. The security account remains protected from closure.
* Added optional `account_delete_timeout` for managed member accounts, including the security account. The default is null, preserving provider-default timeouts; callers can configure values such as `30m` without changing creation or update timeouts. Both deployment examples expose the input.


## Major Breaking Change


## Minor Updates


## Minor Breaking Change


## Bug Fixes
* adding md5/etag checksum to the account_configurator config yaml to force terraform update when the file changes
* alter DenyRootSCP.json to permit `iam:GetAccountSummary`, which is required to see if root credentials are present.

## Known Bugs
