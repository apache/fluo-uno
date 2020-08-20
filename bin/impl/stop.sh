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
  accumulo)
    check_dirs ACCUMULO_HOME

    if pgrep -f accumulo\\.start >/dev/null; then
      if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
        "$ACCUMULO_HOME"/bin/stop-all.sh
      else
        "$ACCUMULO_HOME"/bin/accumulo-cluster stop
      fi
    fi

    if [[ $2 != "--no-deps" ]]; then
      check_dirs ZOOKEEPER_HOME HADOOP_HOME
      pgrep -f hadoop\\.yarn >/dev/null && "$HADOOP_HOME"/sbin/stop-yarn.sh
      pgrep -f hadoop\\.hdfs >/dev/null && "$HADOOP_HOME"/sbin/stop-dfs.sh
      pgrep -f QuorumPeerMain >/dev/null && "$ZOOKEEPER_HOME"/bin/zkServer.sh stop
    fi
    ;;
  hadoop)
    check_dirs HADOOP_HOME
    pgrep -f hadoop\\.yarn >/dev/null && "$HADOOP_HOME"/sbin/stop-yarn.sh
    pgrep -f hadoop\\.hdfs >/dev/null && "$HADOOP_HOME"/sbin/stop-dfs.sh
    ;;
  zookeeper)
    check_dirs ZOOKEEPER_HOME
    pgrep -f QuorumPeerMain >/dev/null && "$ZOOKEEPER_HOME"/bin/zkServer.sh stop
    ;;
  # NYI
  # fluo)
  #   
  #   ;;
  *)
    echo "Usage: uno stop <component> [--no-deps]"
    echo -e "\nPossible components:\n"
    echo "    accumulo   Stop Apache Accumulo plus dependencies: Hadoop, ZooKeeper"
    echo "    hadoop     Stop Apache Hadoop"
    echo "    zookeeper  Stop Apache ZooKeeper"
    echo "Options:"
    echo "    --no-deps  Dependencies will stop unless this option is specified. Only works for accumulo component."
    exit 1
    ;;
esac

