#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Get the directory of the script, so we can source files relative to it.
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${scriptdir}/lib/utils.sh"

check_shell_variables APIGEE_PROJECT APIGEE_ENV
check_required_commands openssl jq gcloud 

#check_required_commands curl
printf "\nThis script installs (or re-installs) apigeecli into \$HOME/.apigeecli/bin...\n"

# Locate the apigeecli command. First look in PATH, then in a fallback location.
apigeecli=$(command -v apigeecli)
if [[ -z "${apigeecli}" ]]; then
    fallback_path="$HOME/.apigeecli/bin/apigeecli"
    if [[ -x "${fallback_path}" ]]; then
        apigeecli="${fallback_path}"
    else
        echo "Error: The 'apigeecli' command was not found." >&2
        echo "Please run 2-install-apigeecli.sh, or ensure apigeecli is in your PATH or in \$HOME/.apigeecli/bin." >&2
        exit 1
    fi
fi

TOKEN=$(gcloud auth print-access-token)

# 1. import 
$apigeecli apis create bundle -f ./bundle/apiproxy --name kvm-read-test-1 -o "${APIGEE_PROJECT}" --token "${TOKEN}" --quiet

# 2. deploy
$apigeecli apis deploy --wait --name kvm-read-test-1 --ovr --org "${APIGEE_PROJECT}" --env "${APIGEE_ENV}" --token "${TOKEN}" --quiet
