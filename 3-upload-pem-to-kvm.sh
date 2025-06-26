#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

# Get the directory of the script, so we can source files relative to it.
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${scriptdir}/lib/utils.sh"

check_shell_variables APIGEE_PROJECT APIGEE_ENV
check_required_commands openssl jq gcloud curl

TOKEN=$(gcloud auth print-access-token)

# The apigeecli call returns a JSON array of KVM names.
# We use jq to parse the JSON and mapfile to read the names into a shell
# array named 'kvm_names'.
mapfile -t kvm_names < <(apigeecli kvms list --env "${APIGEE_ENV}" --org "${APIGEE_PROJECT}" --token "${TOKEN}" | jq -r '.[]')

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
kvm_entry_names=()
if (( kvm_exists == 1 )); then
    echo
    echo "Checking for existing entries in KVM '${selected_kvm_name}'..."
    # The apigeecli call returns a JSON object.
    # We use jq to parse the JSON and mapfile to read the entry names into a shell
    # array named 'kvm_entry_names'. Note the use of APIGEE_PROJECT for the org.
    mapfile -t kvm_entry_names < <(apigeecli kvms entries list -m "${selected_kvm_name}" --org "${APIGEE_PROJECT}" --env "${APIGEE_ENV}" | jq -r '.keyValueEntries[].name')
    if (( ${#kvm_entry_names[@]} > 0 )); then
        echo "Found existing entries."
    else
        echo "No existing entries found."
    fi
fi


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


# 5. if the selected_kvm_name does not already exist, create it here.
apigee=https://apigee.googleapis.com
if (( kvm_exists == 0 )); then
echo "Creating the kvm ${selected_kvm_name}..."
curl -X POST "${apigee}/v1/organizations/${APIGEE_PROJECT}/environments/${APIGEE_ENV}/keyvaluemaps" \
 -H "Authorization: Bearer $TOKEN" \
 -H "Content-Type: application/json" \
  -d '{
  "name": "'"${selected_kvm_name}"'",
  "encrypted": true
 }'
fi

# Helper function to check if a KVM entry exists in the kvm_entry_names array.
function entry_name_exists() {
    local entry_to_find=$1
    for entry in "${kvm_entry_names[@]}"; do
        if [[ "$entry" == "$entry_to_find" ]]; then
            return 0 # found (success)
        fi
    done
    return 1 # not found (failure)
}

# 6. create or update the entries for the key pair.
echo
echo "Creating/updating KVM entries..."

for key_type in public private; do
    echo "Processing ${key_type} key..."
    entry_name="${key_type}key"
    key_file=""
    if [[ "${key_type}" == "public" ]]; then
        key_file="${public_key_file}"
    else
        key_file="${private_key_file}"
    fi

    # Either of these works to get the content of the key file:
    #content=$(<"${key_file}")
    content=$(cat ${key_file} | sed 's/^[ ]*//g' | tr '\n' $ | sed 's/\$/\n/g')

    if entry_name_exists "${entry_name}"; then
        # Entry exists, so update it with PUT.
        echo "Entry '${entry_name}' exists. Updating it."
        payload=$(jq -n --arg name "${entry_name}" --arg value "${content}" '{name: $name, value: $value}')
        curl -s -X PUT "${apigee}/v1/organizations/${APIGEE_PROJECT}/environments/${APIGEE_ENV}/keyvaluemaps/${selected_kvm_name}/entries/${entry_name}" \
             -H "Authorization: Bearer $TOKEN" \
             -H "Content-Type: application/json" \
             -d "${payload}"
    else
        # Entry does not exist, so create it with POST.
        echo "Entry '${entry_name}' does not exist. Creating it."
        payload=$(jq -n --arg name "${entry_name}" --arg value "${content}" '{name: $name, value: $value}')
        curl -s -X POST "${apigee}/v1/organizations/${APIGEE_PROJECT}/environments/${APIGEE_ENV}/keyvaluemaps/${selected_kvm_name}/entries" \
             -H "Authorization: Bearer $TOKEN" \
             -H "Content-Type: application/json" \
             -d "${payload}"
    fi
    echo
done

echo ""
echo ""
echo "The contents of the KVM: "

# AI! filter the the output here of the below comment through jq to pretty-print the json
apigeecli kvms entries list -m "${selected_kvm_name}" --org "${APIGEE_PROJECT}" --env "${APIGEE_ENV}"
