#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables    APIGEE_PROJECT   APIGEE_ENV

check_required_commands openssl jq

# The apigeecli call returns a JSON array of KVM names.
# We use jq to parse the JSON and mapfile to read the names into a shell
# array named 'kvm_names'.
mapfile -t kvm_names < <(apigeecli kvms list --env "${APIGEE_ENV}" --org "${APIGEE_PROJECT}" | jq -r '.[]')

# Prompt for the name of the new KVM.
read -r -p "Name of the to-be-created environment-scoped Key Value Map:? " new_kvm_name

# Check if the KVM already exists.
for existing_kvm in "${kvm_names[@]}"; do
    if [[ "${existing_kvm}" == "${new_kvm_name}" ]]; then
        echo "that KVM already exists. Exiting."
        exit 1
    fi
done
