#!/bin/bash

sudo apt install ansible -y

ansible-playbook ~/development-vm/bootstrap.yml
