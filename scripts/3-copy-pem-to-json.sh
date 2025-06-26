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

# 1. Prompt the user to select an existing KVM or create a new one.
echo
echo "Select a KVM to update, or select 0 to create a new one:"
i=1
for name in "${kvm_names[@]}"; do
    printf "  [%d] %s\n" "$i" "$name"
    ((i++))
done
printf "  [0] %s\n" "enter a new name"
echo

selected_kvm_name=""
kvm_exists=0
while true; do
    read -r -p "Your choice: " choice
    # Validate that choice is a number
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        continue
    fi

    # Validate that choice is in the valid range
    if (( choice < 0 || choice > ${#kvm_names[@]} )); then
        echo "Invalid choice. Please select a number from the list."
        continue
    fi

    # Handle the choice
    if (( choice == 0 )); then
        read -r -p "Enter the name for the new KVM: " selected_kvm_name
        # Check if the new name is empty
        if [[ -z "$selected_kvm_name" ]]; then
            echo "KVM name cannot be empty. Exiting."
            exit 1
        fi
        # Check if the KVM already exists.
        for existing_kvm in "${kvm_names[@]}"; do
            if [[ "${existing_kvm}" == "${selected_kvm_name}" ]]; then
                echo "A KVM with the name '${selected_kvm_name}' already exists. Exiting."
                exit 1
            fi
        done
    else
        # Array is 0-indexed, choice is 1-indexed
        selected_kvm_name="${kvm_names[choice-1]}"
        echo "You selected existing KVM: ${selected_kvm_name}"
        kvm_exists=1
    fi
    break # Exit the validation loop
done

# 2. collect known entries
# AI! if the kvm exists, collect the names of the entries in that KVM.
# Use the command shown below. The output of the command will be structured like
# this:
#   {
#     "keyValueEntries": [
#       {
#         "name": "name-of-entry1",
#         "value": "-value-of-entry-1"
#       }
#       {
#         "name": "name-of-entry2",
#         "value": "-value-of-entry-2"
#       }
#     ]  
#   }
# Use the jq tool to get the list of entry names in the existing kvm. 
apigeecli kvms entries list -m "${selected_kvm_name}" --org "${APIGEE_ENV}" --env "${APIGEE_ENV}"


# 3. find the public/private key pair
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

# 4. Confirm with the user before proceeding.
echo
echo "Found this key pair:"
echo "  public:  ${public_key_file}"
echo "  private: ${private_key_file}"
echo
read -r -p "Insert this key pair into the KVM '${selected_kvm_name}'? [y/N] " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "User declined. Exiting."
  exit 0
fi


# Create the output directory if it doesn't exist.
mkdir -p data-folder

# Construct the output filename.
output_filename="data-folder/env__${APIGEE_ENV}__${selected_kvm_name}__kvmfile__0.json"

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



apigee=https://apigee.googleapis.com
echo "Now, run this command: "
echo "curl -X POST $apigee/v1/organizations/\${APIGEE_PROJECT}/environments/\${APIGEE_ENV}/keyvaluemaps/:kvm/entries/entry-3"
