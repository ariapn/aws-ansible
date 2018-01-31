#!/bin/bash

ROOT=$(dirname $0)/.

exec ansible-playbook ${ROOT}/ansible-aws.yml -i ${ROOT}/inventory --ask-vault-pass $@
