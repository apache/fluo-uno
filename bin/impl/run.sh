#! /usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck source=bin/impl/util.sh
source "$UNO_HOME"/bin/impl/util.sh

[[ -n $LOGS_DIR ]] && rm -f "$LOGS_DIR"/setup/*.{out,err}
echo "Running $1 (detailed logs in $LOGS_DIR/setup)..."
save_console_fd
case "$1" in
  hadoop|zookeeper)
    run_component "$1"
    ;;
  accumulo|fluo|fluo-yarn)
    run_component "$1" "$2"
    ;;
  *)
    echo "Usage: uno run <component> [--no-deps]"
    echo -e "\nPossible components:\n"
    echo "    accumulo   Runs Apache Accumulo and its dependencies (Hadoop & ZooKeeper)"
    echo "    hadoop     Runs Apache Hadoop"
    echo "    fluo       Runs Apache Fluo and its dependencies (Accumulo, Hadoop, & ZooKeeper)"
    echo "    fluo-yarn  Runs Apache Fluo YARN and its dependencies (Fluo, Accumulo, Hadoop, & ZooKeeper)"
    echo -e "    zookeeper     Runs Apache ZooKeeper\n"
    echo "Options:"
    echo "    --no-deps  Dependencies will be setup unless this option is specified. Only works for fluo & accumulo components."
    exit 1
    ;;
esac

# shellcheck disable=SC2181
if [[ $? -eq 0 ]]; then
  echo "Run complete."
else
  echo "Run failed!"
  false
fi

