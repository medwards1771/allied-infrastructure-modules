# CloudTrail Logs

This Terraform Module enables [AWS CloudTrail](https://aws.amazon.com/cloudtrail/), a service for logging every API
call made against your AWS account. This is important in the case of audits, for debugging issues, and investigating
security breaches.
 
This module will create an S3 Bucket where CloudTrail events can be stored, a KMS Customer Master Key (CMK) used to 
encrypt CloudTrail events, and the CloudTrail "Trail" itself to enable API events to be recorded and stored in S3.

## Core concepts and known issues

To understand core concepts like what is CloudTrail, where logs are stored, what logs look like and viewing logs, and also 
to read about known issues, see the [Gruntwork cloudtrail module documentation](https://github.com/gruntwork-io/module-security/blob/master/modules/cloudtrail/README.md)
