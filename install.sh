#!/bin/bash

TZ=Europe/London DEBIAN_FRONTEND=noninteractive sudo apt-get install ansible -y

ansible-playbook ~/development-vm/bootstrap.yml
