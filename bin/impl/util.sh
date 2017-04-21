#! /usr/bin/env bash

# Copyright 2014 Uno authors (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function verify_exist_hash() {
  tarball=$1
  expected_hash=$(echo "${2// /}" | tr '[:upper:]' '[:lower:]')

  if [[ ! -f "$DOWNLOADS/$tarball" ]]; then
    echo "The tarball $tarball does not exist in downloads/"
    exit 1
  fi

  local HASH_CMD
  case "${#expected_hash}" in
    32) HASH_CMD='md5sum' ;;
    40) HASH_CMD='shasum -a 1' ;;
    64) HASH_CMD='shasum -a 256' ;;
    128) HASH_CMD='shasum -a 512' ;;
    *)
      echo "Expected checksum ($expected_hash) of $tarball is not an MD5, SHA1, SHA256, or SHA512 sum"
      exit 1
      ;;
  esac
  actual_hash=$($HASH_CMD "$DOWNLOADS/$tarball" | awk '{print $1}')

  if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo "The actual checksum ($actual_hash) of $tarball does not match the expected checksum ($expected_hash)"
    exit 1
  fi
}

# Takes directory variables as arguments
function check_dirs() {
  for arg in "$@"; do
    if [[ ! -d "${!arg}" ]]; then
      echo "$arg=${!arg} is not a valid directory. Please make sure it exists"
      exit 1
    fi
  done
}
