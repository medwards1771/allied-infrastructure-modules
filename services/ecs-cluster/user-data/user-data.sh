#!/bin/bash
#
# This script is meant to be run in the User Data of each ECS instance. It does the following:
#
# 1. Registers the instance with the proper ECS cluster.
# 2. Authenticates the instance with the proper private Docker repo.
# 3. Runs the CloudWatch Logs Agent to send all data in syslog to CloudWatch
#
# Note, this script:
#
# 1. Assumes it is running in the AMI built from the ../packer/ecs-node.json Packer template.
# 2. Has a number of variables filled in using Terraform interpolation.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function start_cloudwatch_logs_agent {
  local -r vpc_name="$1"
  local -r log_group_name="$2"

  echo "Starting CloudWatch Logs Agent in VPC $vpc_name"
  /etc/user-data/cloudwatch-log-aggregation/run-cloudwatch-logs-agent.sh --vpc-name "$vpc_name" --log-group-name "$log_group_name"
}

function start_fail2ban {
  echo "Starting fail2ban"
  /etc/user-data/configure-fail2ban-cloudwatch/configure-fail2ban-cloudwatch.sh --cloudwatch-namespace Fail2Ban
}

function configure_ecs_instance {
  local -r aws_region="$1"
  local -r ecs_cluster_name="$2"
  local -r vpc_name="$3"
  local -r log_group_name="$4"

  start_cloudwatch_logs_agent "$vpc_name" "$log_group_name"

  start_fail2ban

  echo "Running configure-ecs-instance to authenticate with the Docker registry"
  /usr/local/bin/configure-ecs-instance --ecs-cluster-name "$ecs_cluster_name" --docker-auth-type "ecr" --ecr-aws-region "$aws_region"

  # Lock down the EC2 metadata endpoint so only the root and default users can access it
  /usr/local/bin/ip-lockdown 169.254.169.254 ec2-user root
}

# These variables are set by Terraform interpolation
configure_ecs_instance "${aws_region}" "${ecs_cluster_name}" "${vpc_name}" "${log_group_name}"

