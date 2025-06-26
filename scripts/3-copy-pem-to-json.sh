#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables    APIGEE_PROJECT   APIGEE_ENV

check_required_commands openssl jq

# AI! The result of this call is a JSON array, like so:
# [ "foo", "bar", "bam" ]
# The whitespace between entries may be newlines. Parse it into
# a shell array.  You can use the jq command if that is helpful. 
apigeecli kvms list --env "${APIGEE_ENV}" --org "${APIGEE_PROJECT}" 
