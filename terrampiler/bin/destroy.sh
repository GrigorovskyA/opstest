#!/usr/bin/env bash
set -x

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${CURRENT_DIR}/..

terraform destroy -auto-approve
