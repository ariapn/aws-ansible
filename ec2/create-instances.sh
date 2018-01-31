#!/bin/bash

ROOT=$(dirname $0)/.

exec ansible-playbook ${ROOT}/rstudio-aws.yml -i ${ROOT}/inventory --ask-vault-pass $@
