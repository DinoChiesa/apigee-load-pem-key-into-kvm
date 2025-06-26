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
scriptdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${scriptdir}/lib/utils.sh

check_required_commands curl
printf "\nThis script installs (or re-installs) apigeecli into \$HOME/.apigeecli/bin...\n"

curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
#export PATH=$PATH:$HOME/.apigeecli/bin
