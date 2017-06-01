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

if [[ -z "$FLUO_YARN_REPO" ]]; then
  verify_exist_hash "$FLUO_YARN_TARBALL" "$FLUO_YARN_HASH"
fi

if [[ $1 != "--no-deps" ]]; then
  "$UNO_HOME"/bin/impl/setup-fluo.sh
fi

if [[ -f "$DOWNLOADS/$FLUO_YARN_TARBALL" ]]; then
  echo "Setting up Apache Fluo YARN launcher at $FLUO_YARN_HOME"
  # Don't stop if pkills fail
  set +e
  pkill -f "fluo\.yarn"
  pkill -f twill.launcher
  set -e

  rm -rf "$INSTALL"/fluo-yarn*

  tar xzf "$DOWNLOADS/$FLUO_YARN_TARBALL" -C "$INSTALL"/

  YARN_PROPS=$FLUO_YARN_HOME/conf/fluo-yarn.properties
  $SED "s/.*fluo.worker.num.threads=.*/fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$YARN_PROPS"
  $SED "s/.*fluo.yarn.worker.max.memory.mb=.*/fluo.yarn.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$YARN_PROPS"
  $SED "s/.*fluo.yarn.worker.instances=.*/fluo.yarn.worker.instances=$FLUO_WORKER_INSTANCES/g" "$YARN_PROPS"
  $SED "s#HADOOP_PREFIX=/path/to/hadoop#HADOOP_PREFIX=$HADOOP_PREFIX#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh
  $SED "s#ACCUMULO_HOME=/path/to/accumulo#ACCUMULO_HOME=$ACCUMULO_HOME#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh
  $SED "s#ZOOKEEPER_HOME=/path/to/zookeeper#ZOOKEEPER_HOME=$ZOOKEEPER_HOME#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh

  "$FLUO_YARN_HOME"/lib/fetch.sh extra

  echo "Apache Fluo YARN launcher setup complete"

  stty sane
else
  echo "WARNING: Apache Fluo YARN launcher tarball '$FLUO_YARN_TARBALL' was not found in $DOWNLOADS."
  echo "Apache Fluo YARN launcher will not be set up!"
fi
