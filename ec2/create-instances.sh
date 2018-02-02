#!/bin/bash

ROOT=$(dirname $0)/.

exec ansible-playbook -i ${ROOT}/inventory --ask-vault-pass $@
