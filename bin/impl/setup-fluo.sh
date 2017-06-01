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

source "$UNO_HOME"/bin/impl/util.sh

# stop if any command fails
set -e

if [[ -z "$FLUO_REPO" ]]; then
  verify_exist_hash "$FLUO_TARBALL" "$FLUO_HASH"
fi

if [[ $1 != "--no-deps" ]]; then
  "$UNO_HOME"/bin/impl/setup-accumulo.sh
fi

if [[ -f "$DOWNLOADS/$FLUO_TARBALL" ]]; then
  echo "Setting up Apache Fluo at $FLUO_HOME"
  # Don't stop if pkills fail
  set +e
  pkill -f fluo.yarn
  pkill -f MiniFluo
  pkill -f twill.launcher
  set -e

  rm -rf "$INSTALL"/fluo-*

  tar xzf "$DOWNLOADS/$FLUO_TARBALL" -C "$INSTALL"/

  if [ -d "$FLUO_HOME/conf/examples" ]; then
    cp "$FLUO_HOME"/conf/examples/* "$FLUO_HOME"/conf/
  fi
  FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
  $SED "s#fluo.admin.hdfs.root=.*#fluo.admin.hdfs.root=hdfs://localhost:8020#g" "$FLUO_PROPS"
  $SED "s/fluo.client.accumulo.instance=/fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" "$FLUO_PROPS"
  $SED "s/fluo.client.accumulo.user=/fluo.client.accumulo.user=$ACCUMULO_USER/g" "$FLUO_PROPS"
  $SED "s/fluo.client.accumulo.password=/fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" "$FLUO_PROPS"
  $SED "s/.*fluo.worker.num.threads=.*/fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$FLUO_PROPS"
  $SED "s/.*fluo.yarn.worker.max.memory.mb=.*/fluo.yarn.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$FLUO_PROPS"
  $SED "s/.*fluo.yarn.worker.instances=.*/fluo.yarn.worker.instances=$FLUO_WORKER_INSTANCES/g" "$FLUO_PROPS"
  APP_PROPS=$FLUO_HOME/conf/application.properties
  $SED "s/fluo.accumulo.instance=/fluo.accumulo.instance=$ACCUMULO_INSTANCE/g" "$APP_PROPS"
  $SED "s/fluo.accumulo.user=/fluo.accumulo.user=$ACCUMULO_USER/g" "$APP_PROPS"
  $SED "s/fluo.accumulo.password=/fluo.accumulo.password=$ACCUMULO_PASSWORD/g" "$APP_PROPS"
  $SED "s/.*fluo.worker.num.threads=.*/fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$APP_PROPS"
  $SED "s#HADOOP_PREFIX=/path/to/hadoop#HADOOP_PREFIX=$HADOOP_PREFIX#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ACCUMULO_HOME=/path/to/accumulo#ACCUMULO_HOME=$ACCUMULO_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ZOOKEEPER_HOME=/path/to/zookeeper#ZOOKEEPER_HOME=$ZOOKEEPER_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh

  "$FLUO_HOME"/lib/fetch.sh extra

  echo "Apache Fluo setup complete"

  stty sane
else
  echo "WARNING: Apache Fluo tarball '$FLUO_TARBALL' was not found in $DOWNLOADS."
  echo "Apache Fluo will not be set up!"
fi
