#!/bin/bash

echo "Installing dotfiles."

sudo apt-get update
sudo apt-get install ansible -y

ansible-playbook ./bootstrap.yml
