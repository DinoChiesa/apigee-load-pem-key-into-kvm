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
source ${scriptdir}/lib/utils.sh

check_required_commands openssl

printf "\nThis script uses the openssl command to generate an RSA public+private\n"
printf "key pair, stored in local filesystem files.\n\n"


TIMESTAMP=$(date +'%Y%m%d-%H%M')
PRIVATE_KEY_FILE="rsa-private-key-${TIMESTAMP}.pem"
PUBLIC_KEY_FILE="rsa-public-key-${TIMESTAMP}.pem"
openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:2048 -out "${PRIVATE_KEY_FILE}"
openssl pkey -pubout -inform PEM -in "${PRIVATE_KEY_FILE}" -out "${PUBLIC_KEY_FILE}"

echo ""
echo "Done."
echo ""
echo "private key: ${PRIVATE_KEY_FILE}"
echo "public key:  ${PUBLIC_KEY_FILE}"
echo ""
