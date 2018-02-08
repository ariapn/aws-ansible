#!/bin/bash

ROOT=$(dirname $0)/.

exec ansible-playbook -i ${ROOT}/hosts --ask-vault-pass $@
