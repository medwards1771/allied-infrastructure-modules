# Cloudwatch Dashboard

This Terraform Module creates a Cloudwatch dashboard to monitor deployed
resources including databases, ECS clusters/services and load balancers.


Under the hood, this is all implemented using the [CloudWatch Dashboard Terraform
Module](https://github.com/gruntwork-io/module-aws-monitoring/tree/master/modules/metrics/cloudwatch-dashboard) from the Gruntwork
[module-data-storage](https://github.com/gruntwork-io/module-data-storage) repo. If you don't have
access to this repo, email [support@gruntwork.io](mailto:support@gruntwork.io).

## How do you use this module?

See the [root README](/README.md) for instructions on using modules.
