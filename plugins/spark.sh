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

if [[ ! -f "$DOWNLOADS/$SPARK_TARBALL" ]]; then
  apache_mirror=$(curl -sk https://apache.org/mirrors.cgi?as_json | grep preferred | cut -d \" -f 4)
  if [ -z "$apache_mirror" ]; then
    echo "Failed querying apache.org for best download mirror!"
  fi
  download_apache "spark/spark-$SPARK_VERSION" "$SPARK_TARBALL" "$SPARK_HASH"
fi

verify_exist_hash "$SPARK_TARBALL" "$SPARK_HASH"

if [[ ! -d "$HADOOP_HOME" ]]; then
  print_to_console "Apache Hadoop needs to be setup before Apache Spark can be setup."
  exit 1
fi

print_to_console "Installing Apache Spark at $SPARK_HOME"

pkill -f org.apache.spark.deploy.history.HistoryServer

# stop if any command fails
set -e

rm -rf "$INSTALL"/spark-*
rm -f "$LOGS_DIR"/spark/*
rm -rf "$DATA_DIR"/spark
mkdir -p "$LOGS_DIR"/spark
mkdir -p "$DATA_DIR"/spark/events

tar xzf "$DOWNLOADS/$SPARK_TARBALL" -C "$INSTALL"

cp "$UNO_HOME"/plugins/spark/* "$SPARK_HOME"/conf
$SED "s#DATA_DIR#$DATA_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf

export SPARK_LOG_DIR=$LOGS_DIR/spark
"$SPARK_HOME"/sbin/start-history-server.sh

print_to_console "Apache Spark History Server is running"
print_to_console "    * view at http://localhost:18080/"
