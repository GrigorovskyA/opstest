#!/usr/bin/env bash
set -e

export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${CURRENT_DIR}/..

terraform destroy -auto-approve
