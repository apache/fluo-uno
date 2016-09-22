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

source $FLUO_DEV/bin/impl/util.sh

"$FLUO_DEV"/bin/impl/kill.sh

# stop if any command fails
set -e

echo "Setting up Accumulo"
"$FLUO_DEV"/bin/impl/setup-accumulo.sh

echo "Setting up Fluo"
"$FLUO_DEV"/bin/impl/setup-fluo-only.sh

if [[ "$SETUP_METRICS" == "true" ]]; then
  echo "Setting up Metrics"
  "$FLUO_DEV"/bin/impl/setup-metrics.sh
fi

stty sane

echo -e "\nSetup is finished!"
