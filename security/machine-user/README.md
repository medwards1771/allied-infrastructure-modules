# Machine user module

This is a simple module to create a "machine user" in IAM that can be used in CI / CD builds. This module gives the 
user the IAM permissions you specify and adds the user to IAM groups you specify.
 
Please note that this module does NOT create any credentials for the user. Once the user exists, you would typically
go into IAM, create access keys for the user, and copy and paste them into your CI system as environment variables.