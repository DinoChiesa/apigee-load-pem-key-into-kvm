#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Get the directory of the script, so we can source files relative to it.
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${scriptdir}/lib/utils.sh"

check_shell_variables APIGEE_PROJECT APIGEE_ENV
check_required_commands openssl jq gcloud 

#check_required_commands curl
printf "\nThis script installs (or re-installs) apigeecli into \$HOME/.apigeecli/bin...\n"

# AI!   Locate the apigeecli command.  First look in any of the directories on
# the path.  If not found there, then look in $HOME/.apigeecli/bin .
# If not found in either place, exit, printing an appropriate message. 
# If found, set the variable apigeecli to hold the location of the executable.

TOKEN=$(gcloud auth print-access-token)

# 1. import 
$apigeecli apis create bundle -f ./bundle/apiproxy --name kvm-read-test-1 -o "${APIGEE_PROJECT}" --token "${TOKEN}" --quiet

# 2. deploy
$apigeecli apis deploy --wait --name kvm-read-test-1 --ovr --org "${APIGEE_PROJECT}" --env "${APIGEE_ENV}" --token "${TOKEN}" --quiet


