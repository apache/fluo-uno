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

source "$FLUO_DEV"/bin/impl/util.sh

verify_exist_hash "$SPARK_TARBALL" "$SPARK_HASH"

if [[ ! -d "$HADOOP_PREFIX" ]]; then
  echo "Apache Hadoop needs to be setup before Apache Spark can be setup."
  exit 1
fi

echo "Setting up Apache Spark at $SPARK_HOME"

pkill -f org.apache.spark.deploy.history.HistoryServer

# stop if any command fails
set -e

rm -rf "$INSTALL"/spark-*
rm -f "$LOGS_DIR"/spark/*
rm -rf "$DATA_DIR"/spark
mkdir -p "$LOGS_DIR"/spark
mkdir -p "$DATA_DIR"/spark/events

tar xzf "$DOWNLOADS/$SPARK_TARBALL" -C "$INSTALL"

cp "$FLUO_DEV"/conf/spark/* "$SPARK_HOME"/conf
$SED "s#DATA_DIR#$DATA_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf

export SPARK_LOG_DIR=$LOGS_DIR/spark
"$SPARK_HOME"/sbin/start-history-server.sh

echo "Apache Spark setup complete"
