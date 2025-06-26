#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables    APIGEE_PROJECT   APIGEE_ENV

check_required_commands openssl jq

# The apigeecli call returns a JSON array of KVM names.
# We use jq to parse the JSON and mapfile to read the names into a shell
# array named 'kvm_names'.
mapfile -t kvm_names < <(apigeecli kvms list --env "${APIGEE_ENV}" --org "${APIGEE_PROJECT}" | jq -r '.[]')

# AI! Prompt request input from the user:
#
#   Name of the to-be-created environment-scoped Key Value Map:?
#
# Store this value into a local variable here.
# Then, check to see if the Name the user specified is in the list of
# names retrieved by the prior command.  If present, print
# a message like "that KVM already exists. Exiting. " and exit. 
