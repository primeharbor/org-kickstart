# Bootstraping a new account

These is the list of tasks that need to be done via ClickOps in a new AWS Account before you can deploy org-kickstart.


## Root Tasks
1. [Add MFA to root](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials)
2. [Enable IAM access to billing](https://us-east-1.console.aws.amazon.com/billing/home?region=us-east-1#/account) (this is still a thing in 2023?)
3. Go to [Organizations](https://us-east-1.console.aws.amazon.com/organizations/v2/home?region=us-east-1#) and create an Organization
4. Go to [AWS SSO](https://us-east-1.console.aws.amazon.com/singlesignon/home?region=us-east-1#!/), and enable it
5. Add yourself as a [user](https://us-east-1.console.aws.amazon.com/singlesignon/home?region=us-east-1#!/instances/fnord/users$addUserWizard)
6. [Create a pre-defined](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/organization/permission-sets/create)  Permission Set named ***TempAdministratorAccess***. Probably want the duration as 4 hours.
7. [Assign](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/organization/accounts) the Permission Set to the new Payer/Org Management Account

Log out of root and never use it again.


## On your machine
1. Check Email and create your IAM Identity Center account.
1. Add MFA to that account
1. Import Admin creds to environment

You're now ready to run org-kickstart