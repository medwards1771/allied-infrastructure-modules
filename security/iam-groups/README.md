# IAM Groups

This Terraform Module creates a best practices set of [IAM Groups](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html)
based on the Gruntwork [iam-groups module](https://github.com/gruntwork-io/module-security/tree/master/modules/iam-groups).

If you need additional IAM Groups not defined in the module, add them directly in the `main.tf` file below the module.

## Core concepts

To understand core concepts like what is an IAM Group and how do you sanely manage the highly granular permissions enabled
by IAM, see the [iam-groups documentation](https://github.com/gruntwork-io/module-security/blob/master/modules/iam-groups/README.md)