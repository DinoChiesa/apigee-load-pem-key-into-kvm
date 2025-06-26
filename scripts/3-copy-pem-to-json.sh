#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Get the directory of the script, so we can source files relative to it.
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "${scriptdir}/lib/utils.sh"

check_shell_variables APIGEE_PROJECT APIGEE_ENV

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

# Find the latest public key file matching the naming convention.
# The ls with sort and head is a reliable way to get the latest file
# given the YYYYMMDD-HHmm timestamp format.
public_key_file=$(ls -1 rsa-public-key-*.pem 2>/dev/null | sort -r | head -n 1)

if [[ -z "${public_key_file}" ]]; then
  echo "No public key file of the form rsa-public-key-*.pem was found. Exiting."
  exit 1
fi

# Derive the private key filename from the public key filename.
private_key_file="${public_key_file/public/private}"

if [[ ! -f "${private_key_file}" ]]; then
  echo "Found public key ${public_key_file}, but the corresponding private key"
  echo "${private_key_file} is missing. Exiting."
  exit 1
fi

# Confirm with the user before proceeding.
echo
echo "Found this key pair:"
echo "  public:  ${public_key_file}"
echo "  private: ${private_key_file}"
echo
read -r -p "Insert this key pair into the KVM '${new_kvm_name}'? [y/N] " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "User declined. Exiting."
  exit 0
fi

# Create the output directory if it doesn't exist.
mkdir -p data-folder

# Construct the output filename.
output_filename="data-folder/env__${APIGEE_ENV}__${new_kvm_name}__kvmfile__0.json"

# Read the key files' content.
public_key_content=$(<"${public_key_file}")
private_key_content=$(<"${private_key_file}")

# Use jq to construct the JSON payload and write it to the file.
# The -n flag creates the JSON from scratch.
# --arg passes the key contents as string variables to jq, which handles escaping.
jq -n \
  --arg pubkey "${public_key_content}" \
  --arg privkey "${private_key_content}" \
  '{
     "keyValueEntries": [
       {
         "name": "public",
         "value": $pubkey
       },
       {
         "name": "private",
         "value": $privkey
       }
     ],
     "nextPageToken": ""
   }' >"${output_filename}"

echo
echo "Successfully created KVM data file:"
echo "  ${output_filename}"
echo
cat ${output_filename}
