#!/bin/bash


sudo apt-get install python3 pip3 -y

pip3 install ansible

ansible-playbook ~/development-vm/bootstrap.yml
