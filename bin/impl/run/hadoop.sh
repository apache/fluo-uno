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

pkill -f hadoop.hdfs
pkill -f hadoop.yarn

# stop if any command fails
set -e

"$HADOOP_HOME"/bin/hdfs namenode -format
"$HADOOP_HOME"/sbin/start-dfs.sh
"$HADOOP_HOME"/sbin/start-yarn.sh

namenode_port=9870
if [[ $HADOOP_VERSION =~ ^2\..*$ ]]; then
  namenode_port=50070
  export HADOOP_PREFIX=$HADOOP_HOME
fi

print_to_console "Apache Hadoop $HADOOP_VERSION is running"
print_to_console "    * NameNode status: http://localhost:$namenode_port/"
print_to_console "    * ResourceManager status: http://localhost:8088/"
print_to_console "    * view logs at $HADOOP_LOG_DIR"
