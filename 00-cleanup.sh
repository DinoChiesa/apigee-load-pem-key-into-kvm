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

pname=kvm-read-test-1
# Get the directory of the script, so we can source files relative to it.
scriptdir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "${scriptdir}/lib/utils.sh"

check_shell_variables APIGEE_PROJECT APIGEE_ENV
check_required_commands gcloud jq

printf "\nThis script undeploys and deletes the example Apigee API Proxy...\n"

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

delete_apiproxy() {
  local proxy_name ENVNAME REV NUM_DEPLOYS OUTFILE
  proxy_name=$1
  printf "Checking Proxy %s\n" "${proxy_name}"
  if apigeecli apis get --name "$proxy_name" --org "$APIGEE_PROJECT" --token "$TOKEN" --disable-check >/dev/null 2>&1; then
    OUTFILE=$(mktemp /tmp/apigee-samples.apigeecli.out.XXXXXX)
    if apigeecli apis listdeploy --name "$proxy_name" --org "$APIGEE_PROJECT" --token "$TOKEN" --disable-check >"$OUTFILE" 2>&1; then
      NUM_DEPLOYS=$(jq -r '.deployments | length' "$OUTFILE")
      if [[ $NUM_DEPLOYS -ne 0 ]]; then
        echo "Undeploying ${proxy_name}"
        for ((i = 0; i < NUM_DEPLOYS; i++)); do
          ENVNAME=$(jq -r ".deployments[$i].environment" "$OUTFILE")
          REV=$(jq -r ".deployments[$i].revision" "$OUTFILE")
          apigeecli apis undeploy --name "${proxy_name}" --env "$ENVNAME" --rev "$REV" --org "$APIGEE_PROJECT" --token "$TOKEN" --disable-check
        done
      else
        printf "  There are no deployments of %s to remove.\n" "${proxy_name}"
      fi
    fi
    [[ -f "$OUTFILE" ]] && rm -f "$OUTFILE"

    echo "Deleting proxy ${proxy_name}"
    apigeecli apis delete --name "${proxy_name}" --org "$APIGEE_PROJECT" --token "$TOKEN" --disable-check

  else
    printf "  The proxy %s does not exist in project %s.\n" "${proxy_name}" "${APIGEE_PROJECT}"
  fi
}

TOKEN=$(gcloud auth print-access-token)

delete_apiproxy "${pname}"


echo ""
echo "Done."
echo ""
