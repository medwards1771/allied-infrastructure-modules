# RDS Database

This Terraform Module creates a database using the Amazon Relational Database Service (RDS). Note that many logical databases 
can exist on a single physical database.

Under the hood, this is all implemented using the [RDS Terraform
Module](https://github.com/gruntwork-io/module-data-storage/tree/master/modules/rds) from the Gruntwork
[module-data-storage](https://github.com/gruntwork-io/module-data-storage) repo. If you don't have
access to this repo, email [support@gruntwork.io](mailto:support@gruntwork.io).

## How do you use this module?

See the [root README](/README.md) for instructions on using modules.

## Core concepts

To understand core concepts like what is RDS, connecting to the database, and scaling the database, see the [Gruntwork
RDS Module Docs](https://github.com/gruntwork-io/module-data-storage/tree/master/modules/rds).