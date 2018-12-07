#!/usr/bin/env bash
set -x

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
terraform destroy -auto-approve
