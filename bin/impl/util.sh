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
  expected_hash=$2

  if [[ ! $expected_hash =~ $HASH_REGEX ]]; then
    echo "Expected checksum ($expected_hash) of $tarball does not match regex $HASH_REGEX"
    exit 1
  fi
  if [[ ! -f "$DOWNLOADS/$tarball" ]]; then
    echo "The tarball $tarball does not exists in downloads/"
    exit 1
  fi

  actual_hash=$($HASH_CMD "$DOWNLOADS/$tarball" | awk '{print $1}')

  if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo "The actual checksum ($actual_hash) of $tarball does not match the expected checksum ($expected_hash)"
    exit 1
  fi
}
