#!/bin/bash

# sudo apt-get update
# sudo apt-get install ansible -y

source ~/.env
ansible-playbook ~/development-vm/bootstrap${BOOT_STRAP_STYLE}.yml
