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

  rm -rf "$INSTALL"/fluo-[0-9]*

  tar xzf "$DOWNLOADS/$FLUO_TARBALL" -C "$INSTALL"/

  if [[ $FLUO_VERSION =~ ^1\.[0-1].*$ ]]; then
    cp "$FLUO_HOME"/conf/examples/* "$FLUO_HOME"/conf/
    fluo_props=$FLUO_HOME/conf/fluo.properties
  else
    fluo_props=$FLUO_HOME/conf/fluo.properties.deprecated
    conn_props=$FLUO_HOME/conf/fluo-conn.properties
    $SED "s#.*fluo.connection.zookeepers=.*#fluo.connection.zookeepers=$UNO_HOST/fluo#g" "$conn_props"
    app_props=$FLUO_HOME/conf/fluo-app.properties
    $SED "s/fluo.accumulo.instance=/fluo.accumulo.instance=$ACCUMULO_INSTANCE/g" "$app_props"
    $SED "s/fluo.accumulo.user=/fluo.accumulo.user=$ACCUMULO_USER/g" "$app_props"
    $SED "s/fluo.accumulo.password=/fluo.accumulo.password=$ACCUMULO_PASSWORD/g" "$app_props"
    $SED "s/.*fluo.accumulo.zookeepers=.*/fluo.accumulo.zookeepers=$UNO_HOST/g" "$app_props"
    $SED "s#fluo.dfs.root=.*#fluo.dfs.root=hdfs://$UNO_HOST:8020/fluo#g" "$app_props"
    $SED "s/.*fluo.worker.num.threads=.*/fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$app_props"
  fi

  $SED "s#fluo.admin.hdfs.root=.*#fluo.admin.hdfs.root=hdfs://$UNO_HOST:8020#g" "$fluo_props"
  $SED "s/fluo.client.accumulo.instance=/fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" "$fluo_props"
  $SED "s/fluo.client.accumulo.user=/fluo.client.accumulo.user=$ACCUMULO_USER/g" "$fluo_props"
  $SED "s/fluo.client.accumulo.password=/fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" "$fluo_props"
  $SED "s/.*fluo.worker.num.threads=.*/fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$fluo_props"
  $SED "s/.*fluo.yarn.worker.max.memory.mb=.*/fluo.yarn.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$fluo_props"
  $SED "s/.*fluo.yarn.worker.instances=.*/fluo.yarn.worker.instances=$FLUO_WORKER_INSTANCES/g" "$fluo_props"

  $SED "s#HADOOP_PREFIX=.*#HADOOP_PREFIX=$HADOOP_PREFIX#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ACCUMULO_HOME=.*o#ACCUMULO_HOME=$ACCUMULO_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ZOOKEEPER_HOME=.*#ZOOKEEPER_HOME=$ZOOKEEPER_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh

  "$FLUO_HOME"/lib/fetch.sh extra

  echo "Apache Fluo setup complete"

  stty sane
else
  echo "WARNING: Apache Fluo tarball '$FLUO_TARBALL' was not found in $DOWNLOADS."
  echo "Apache Fluo will not be set up!"
fi
