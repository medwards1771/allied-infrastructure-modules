# Cross-account IAM roles 

This Terraform Module creates IAM roles that allow users from your other AWS accounts to access this AWS account. This allows you
to define all of your IAM users in a single account (e.g. a `users` account), and use those same credentials to assume 
specific IAM roles in other accounts (e.g. `stage` and `prod` accounts). 

## Core concepts

To understand core concepts like how these IAM roles work, how to switch between AWS accounts, and more, see the 
[cross-account-iam-roles module documentation](https://github.com/gruntwork-io/module-security/tree/master/modules/cross-account-iam-roles).