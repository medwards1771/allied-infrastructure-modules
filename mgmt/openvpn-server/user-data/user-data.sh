#!/bin/bash
#
# A script run in User Data of the OpenVPN Server during boot.
#
# Note that this script expects to be running in an AMI generated by the Packer template packer/openvpn-server.json.

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

function get_instance_id {
    curl --silent http://169.254.169.254/latest/meta-data/instance-id
}

function get_aws_region {
    curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}'
}

function attach_eip {
  local -r eip_id="$1"

  echo 'Attaching EIP $eip_id...'
  aws ec2 associate-address  \
   --instance-id $(get_instance_id)  \
   --allocation-id "$eip_id"  \
   --region $(get_aws_region)  \
   --allow-reassociation
}

function init_openvpn {
  local -r ca_country="$1"
  local -r ca_state="$2"
  local -r ca_locality="$3"
  local -r ca_org="$4"
  local -r ca_org_unit="$5"
  local -r ca_email="$6"
  local -r backup_bucket_name="$7"
  local -r kms_key_id="$8"
  local -r key_size="$9"
  shift 9
  local -r ca_expiration_days="$1"
  local -r cert_expiration_days="$2"
  local -r vpn_subnet="$3"
  shift 3
  local -a routes=()

  while [[ $# -gt 0 ]]; do
    local route="$1"
    routes+=("--vpn-route" "$route")
    shift 1
  done

  echo 'Initializing PKI and Copying OpenVPN config into place...'
  init-openvpn  \
   --country "$ca_country"  \
   --state "$ca_state"  \
   --locality "$ca_locality"  \
   --org "$ca_org"  \
   --org-unit "$ca_org_unit"  \
   --email "$ca_email"  \
   --s3-bucket-name "$backup_bucket_name"  \
   --kms-key-id "$kms_key_id" \
   --key-size "$key_size" \
   --ca-expiration-days "$ca_expiration_days" \
   --cert-expiration-days "$cert_expiration_days" \
   --vpn-subnet "$vpn_subnet" \
   "$${routes[@]}" # Need a double dollar-sign here to avoid Terraform interpolation
}

function start_openvpn {
  local -r queue_region="$1"

  echo 'Restarting OpenVPN...'
  /etc/init.d/openvpn restart

  echo 'Starting Certificate Request/Revoke Daemons...'
  run-process-requests --region "$queue_region" --request-url "${request_queue_url}"
  run-process-revokes --region "$queue_region" --revoke-url "${revocation_queue_url}"

  touch /etc/openvpn/openvpn-init-complete
}

# The variables below are filled in via Terraform interpolation
start_cloudwatch_logs_agent "${vpc_name}" "${log_group_name}"
start_fail2ban
attach_eip "${eip_id}"
init_openvpn "${ca_country}" "${ca_state}" "${ca_locality}" "${ca_org}" "${ca_org_unit}" "${ca_email}" "${backup_bucket_name}" "${kms_key_id}" "${key_size}" "${ca_expiration_days}" "${cert_expiration_days}" "${vpn_subnet}" ${routes}
start_openvpn "${queue_region}"

# Lock down the EC2 metadata endpoint so only the root and default users can access it
/usr/local/bin/ip-lockdown 169.254.169.254 ubuntu root
