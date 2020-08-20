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

if [[ -z $1 || $1 == '--vars' ]]; then
  echo "export HADOOP_HOME=\"$HADOOP_HOME\""
  [[ $HADOOP_VERSION =~ ^2\..*$ ]] && echo "export HADOOP_PREFIX=\"$HADOOP_HOME\""
  echo "export HADOOP_CONF_DIR=\"$HADOOP_CONF_DIR\""
  echo "export ZOOKEEPER_HOME=\"$ZOOKEEPER_HOME\""
  echo "export SPARK_HOME=\"$SPARK_HOME\""
  echo "export ACCUMULO_HOME=\"$ACCUMULO_HOME\""
  echo "export FLUO_HOME=\"$FLUO_HOME\""
  echo "export FLUO_YARN_HOME=\"$FLUO_YARN_HOME\""
fi

if [[ -z $1 || $1 == '--paths' ]]; then
  echo -n "export PATH=\"\$PATH:$UNO_HOME/bin:$HADOOP_HOME/bin:$ZOOKEEPER_HOME/bin:$ACCUMULO_HOME/bin"
  [[ -d "$SPARK_HOME" ]]     && echo -n ":$SPARK_HOME/bin"
  [[ -d "$FLUO_HOME" ]]      && echo -n ":$FLUO_HOME/bin"
  [[ -d "$FLUO_YARN_HOME" ]] && echo -n ":$FLUO_YARN_HOME/bin"
  [[ -d "$INFLUXDB_HOME" ]]  && echo -n ":$INFLUXDB_HOME/bin"
  [[ -d "$GRAFANA_HOME" ]]   && echo -n ":$GRAFANA_HOME/bin"
  echo '"'
fi

