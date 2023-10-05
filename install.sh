#!/bin/bash

sudo apt-get ansible -y

ansible-playbook ~/development-vm/bootstrap.yml
