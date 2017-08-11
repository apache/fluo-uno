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

case "$1" in
hadoop)
  echo -n "$HADOOP_VERSION"
  ;;
zookeeper)
  echo -n "$ZOOKEEPER_VERSION"
  ;;
accumulo)
  echo -n "$ACCUMULO_VERSION"
  ;;
fluo)
  echo -n "$FLUO_VERSION"
  ;;
fluo-yarn)
  echo -n "$FLUO_YARN_VERSION"
  ;;
spark)
  echo -n "$SPARK_VERSION"
  ;;
influxdb)
  echo -n "$INFLUXDB_VERSION"
  ;;
grafana)
  echo -n "$GRAFANA_VERSION"
  ;;
*)
  echo "You must specify a valid depedency (i.e hadoop, zookeeper, accumulo, etc)"
  exit 1
esac
