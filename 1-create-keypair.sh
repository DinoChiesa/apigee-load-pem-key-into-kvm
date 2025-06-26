#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Get the directory of the script, so we can source files relative to it.
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${scriptdir}/lib/utils.sh

# check_shell_variables FOO BAR

check_required_commands openssl

TIMESTAMP=$(date +'%Y%m%d-%H%M')
PRIVATE_KEY_FILE="rsa-private-key-${TIMESTAMP}.pem"
PUBLIC_KEY_FILE="rsa-public-key-${TIMESTAMP}.pem"
openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:2048 -out "${PRIVATE_KEY_FILE}"
openssl pkey -pubout -inform PEM -in "${PRIVATE_KEY_FILE}" -out "${PUBLIC_KEY_FILE}"
echo ""
echo "private key: ${PRIVATE_KEY_FILE}"
echo "public key:  ${PUBLIC_KEY_FILE}"
echo ""
