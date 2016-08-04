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

source $FLUO_DEV/bin/impl/util.sh

# stop if any command fails
set -e

if [[ -z "$FLUO_REPO" ]]; then
  verify_exist_hash "$FLUO_TARBALL" "$FLUO_MD5"
fi

if [[ -f "$DOWNLOADS/$FLUO_TARBALL" ]]; then
  echo "Killing any Fluo applications (if running)"
  # Don't stop if pkills fail
  set +e
  pkill -f fluo.yarn
  pkill -f MiniFluo
  pkill -f twill.launcher
  set -e

  echo "Removing previous Fluo installs"
  rm -rf "$INSTALL"/fluo-*

  echo "Deploying new Fluo tarball"
  tar xzf "$DOWNLOADS/$FLUO_TARBALL" -C "$INSTALL"/

  echo "Configuring Fluo"
  # Copy example config to deployment
  cp "$FLUO_HOME"/conf/examples/* "$FLUO_HOME"/conf/
  FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
  $SED "s/fluo.client.accumulo.instance=/fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" "$FLUO_PROPS"
  $SED "s/fluo.client.accumulo.user=/fluo.client.accumulo.user=$ACCUMULO_USER/g" "$FLUO_PROPS"
  $SED "s/fluo.client.accumulo.password=/fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" "$FLUO_PROPS"
  $SED "s/.*fluo.yarn.worker.num.threads=.*/fluo.yarn.worker.num.threads=$FLUO_WORKER_THREADS/g" "$FLUO_PROPS"
  $SED "s/.*fluo.yarn.worker.max.memory.mb=.*/fluo.yarn.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$FLUO_PROPS"
  $SED "s/.*fluo.yarn.worker.instances=.*/fluo.yarn.worker.instances=$FLUO_WORKER_INSTANCES/g" "$FLUO_PROPS"
  $SED "s#HADOOP_PREFIX=/path/to/hadoop#HADOOP_PREFIX=$HADOOP_PREFIX#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ACCUMULO_HOME=/path/to/accumulo#ACCUMULO_HOME=$ACCUMULO_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh
  $SED "s#ZOOKEEPER_HOME=/path/to/zookeeper#ZOOKEEPER_HOME=$ZOOKEEPER_HOME#g" "$FLUO_HOME"/conf/fluo-env.sh

  if [[ "$SETUP_METRICS" == "true" ]]; then
    $SED "/fluo.metrics.reporter.graphite/d" "$FLUO_PROPS"
    {
      echo "fluo.metrics.reporter.graphite.enable=true"
      echo "fluo.metrics.reporter.graphite.host=localhost"
      echo "fluo.metrics.reporter.graphite.port=2003"
      echo "fluo.metrics.reporter.graphite.frequency=30"
    } >> "$FLUO_PROPS"
  fi

  $FLUO_HOME/lib/fetch.sh extra
else
  echo "WARNING: Fluo tarball '$FLUO_TARBALL' was not found in $DOWNLOADS."
  echo "Fluo will not be set up!"
fi
