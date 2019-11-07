# Mgmt VPC

This Terraform Module creates a [Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/) that can be used for DevOps
tooling, such as running a bastion host or Jenkins. The resources that are created include:

1. The VPC itself.
1. Subnets, which are isolated subdivisions within the VPC. There are 2 "tiers" of subnets: public and private.
1. Route tables, which provide routing rules for the subnets.
1. Internet Gateways to route traffic to the public Internet from public subnets.
1. NATs to route traffic to the public Internet from private subnets.
1. Network ACLs that control what traffic can go in and out of each subnet.

Under the hood, this is all implemented using Terraform modules from the Gruntwork
[module-vpc](https://github.com/gruntwork-io/module-vpc) repo. If you don't have access to this repo, email
[support@gruntwork.io](mailto:support@gruntwork.io).

## How do you use this module?

See the [root README](/README.md) for instructions on using modules.

## Core concepts

To understand core concepts like what's a VPC, how subnets are configured, how network ACLs work, and more, see the
documentation in the [module-vpc](https://github.com/gruntwork-io/module-vpc) repo.
