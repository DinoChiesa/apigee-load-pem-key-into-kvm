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

# AI! Search the local directory for files with a name of the form
# rsa-public-key-YYYYMMdd-HHmm.pem 
# Sort the list of files alpha-numerically.  Choose the latest file
# (20250623-1123 comes before 20250625-0123)
# If you find a file of that form, then check for a similarly named
# file like rsa-private-key-YYYYMMdd-HHmm.pem , with the same
# timestamp in its name.
#
# If you do not find two files, print an appropriate message and exit.
# IF you find a pair of files, then print a message asking for
# confirmation.  "Insert FILE1 and FILE2 into KVM {KVM Name}? "
#
# IF the user responds No, then exit. 
