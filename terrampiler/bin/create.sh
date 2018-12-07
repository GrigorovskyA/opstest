#!/usr/bin/env bash
set -x

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${CURRENT_DIR}/..

ruby schema.rb > main.tf
terraform init
terraform apply -auto-approve
