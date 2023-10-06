#!/bin/bash

sudo apt-get update
sudo apt-get install ansible -y

ansible-playbook ~/development-vm/bootstrap.yml
