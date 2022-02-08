#!/bin/bash -f
echo "This script will run the required commands to destroy the core environment setup for the lab"
echo "It will only destroy resources created by these scripts, if you reused an existing resource"
echo "then those resources will not be destroyed, and neither will the compartment containing them"
read -p "Are you sure you want to destroy these resources (y/n) ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, stopping script"
  exit 0
else
  echo "OK destroying resources"
  bash database-destroy.sh
  bash user-identity-destroy.sh
  bash compartment-destroy.sh
  bash initials-destroy.sh
fi