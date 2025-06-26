#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-
# Copyright © 2025 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Get the directory of the script, so we can source files relative to it.
scriptdir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
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
pname=kvm-read-test-1
# 1. import
echo "Importing the API proxy bundle..."
if ! $apigeecli apis create bundle -f "./bundle/${pname}/apiproxy" --name "$pname" -o "${APIGEE_PROJECT}" --token "${TOKEN}"; then
  echo "Error: Failed to import the API proxy bundle." >&2
  exit 1
fi
echo "Successfully imported the API proxy."
echo

# 2. deploy
echo "Deploying the API proxy..."
if ! $apigeecli apis deploy --wait --name "$pname" --ovr --org "${APIGEE_PROJECT}" --env "${APIGEE_ENV}" --token "${TOKEN}"; then
  echo "Error: Failed to deploy the API proxy." >&2
  exit 1
fi
echo "Successfully deployed the API proxy."
echo
