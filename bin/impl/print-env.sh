#! /usr/bin/env bash

# Copyright 2014 Fluo authors (see AUTHORS)
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

if [[ -z "$1" || "$1" == "--vars" ]]; then
  echo "export HADOOP_PREFIX=$HADOOP_PREFIX"
  echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR"
  echo "export ZOOKEEPER_HOME=$ZOOKEEPER_HOME"
  echo "export SPARK_HOME=$SPARK_HOME"
  echo "export ACCUMULO_HOME=$ACCUMULO_HOME"
  echo "export FLUO_HOME=$FLUO_HOME"
fi

if [[ -z "$1" || "$1" == "--paths" ]]; then
  echo -n "export PATH=\$PATH:$FLUO_DEV/bin:$HADOOP_PREFIX/bin:$ZOOKEEPER_HOME/bin:$SPARK_HOME/bin:$ACCUMULO_HOME/bin:$FLUO_HOME/bin"
  if [[ "$SETUP_METRICS" == "true" ]]; then
    echo -n ":$INFLUXDB_HOME/bin:$GRAFANA_HOME/bin"
  fi
  echo ""
fi
