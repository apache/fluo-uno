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

case "$1" in
  accumulo|fluo|fluo-yarn)
    install_component "$1" "$2"
    ;;
  hadoop|zookeeper)
    install_component "$1"
    ;;
  *)
    echo "Usage: uno install <component> [--no-deps]"
    echo -e "\nPossible components:\n"
    echo "    accumulo   Installs Apache Accumulo and its dependencies (Hadoop & ZooKeeper)"
    echo "    fluo       Installs Apache Fluo and its dependencies (Accumulo, Hadoop, & ZooKeeper)"
    echo "    fluo-yarn  Installs Apache Fluo YARN"
    echo "    hadoop     Installs Apache Hadoop"
    echo -e "    zookeeper  Installs Apache ZooKeeper\n"
    echo "Options:"
    echo "    --no-deps  Dependencies will be setup unless this option is specified. Only works for fluo & accumulo components."
    exit 1
    ;;
esac

# shellcheck disable=SC2181
if [[ $? -eq 0 ]]; then
  echo "Install complete."
else
  echo "Install failed!"
  false
fi

