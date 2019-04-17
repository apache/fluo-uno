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

source "$UNO_HOME"/bin/impl/util.sh

pkill -f accumulo.start

# stop if any command fails
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

if [[ $1 != "--no-deps" ]]; then
  run_component hadoop
  run_component zookeeper
fi

"$HADOOP_HOME"/bin/hadoop fs -rm -r /accumulo 2> /dev/null || true
"$ACCUMULO_HOME"/bin/accumulo init --clear-instance-name --instance-name "$ACCUMULO_INSTANCE" --password "$ACCUMULO_PASSWORD"
if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  "$ACCUMULO_HOME"/bin/start-all.sh
else
  "$ACCUMULO_HOME"/bin/accumulo-cluster start
fi

print_to_console "Apache Accumulo $ACCUMULO_VERSION is running"
print_to_console "    * Accumulo Monitor: http://localhost:9995/"
print_to_console "    * view logs at $ACCUMULO_LOG_DIR"
