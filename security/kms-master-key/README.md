# KMS Master Key

This Terraform Module creates a [Customer Master
Key (CMK)](http://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys) in [Amazon's Key Management
Service (KMS)](https://aws.amazon.com/kms/) as well as a [Key
Policy](http://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key_permissions) that controls who has
access to the CMK. You can use this CMK to encrypt and decrypt small amounts of data, such as secrets that you store
in a config file.

You can use KMS via the AWS API, CLI, or, for a more streamlined experience, you can use
[gruntkms](https://github.com/gruntwork-io/gruntkms).

## Core concepts

To understand core concepts like what is KMS, what is a Customer Master Key, and how to use them to encrypt and decrypt
data, see the [kms-master-key
module](https://github.com/gruntwork-io/module-security/tree/master/modules/kms-master-key) and
[gruntkms](https://github.com/gruntwork-io/gruntkms).