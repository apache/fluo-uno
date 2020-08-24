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

# shellcheck source=bin/impl/util.sh
source "$UNO_HOME"/bin/impl/util.sh

# stop if any command fails
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

[[ -z $FLUO_YARN_REPO ]] && verify_exist_hash "$FLUO_YARN_TARBALL" "$FLUO_YARN_HASH"

if [[ -f $DOWNLOADS/$FLUO_YARN_TARBALL ]]; then
  print_to_console "WARNING: Apache Fluo YARN launcher tarball '$FLUO_YARN_TARBALL' was not found in $DOWNLOADS."
  print_to_console "Apache Fluo YARN launcher will not be set up!"
fi

print_to_console "Setting up Apache Fluo YARN launcher at $FLUO_YARN_HOME"
# Don't stop if pkills fail
set +e
trap - ERR
pkill -f "fluo\.yarn"
pkill -f twill.launcher
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

rm -rf "${INSTALL:?}"/fluo-yarn*

tar xzf "$DOWNLOADS/$FLUO_YARN_TARBALL" -C "$INSTALL"/

yarn_props=$FLUO_YARN_HOME/conf/fluo-yarn.properties
$SED "s#.*fluo.yarn.zookeepers=.*#fluo.yarn.zookeepers=$UNO_HOST/fluo-yarn#g" "$yarn_props"
$SED "s/.*fluo.yarn.resource.manager=.*/fluo.yarn.resource.manager=$UNO_HOST/g" "$yarn_props"
$SED "s#.*fluo.yarn.dfs.root=.*#fluo.yarn.dfs.root=hdfs://$UNO_HOST:8020/#g" "$yarn_props"
$SED "s/.*fluo.yarn.worker.max.memory.mb=.*/fluo.yarn.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$yarn_props"
$SED "s/.*fluo.yarn.worker.instances=.*/fluo.yarn.worker.instances=$FLUO_WORKER_INSTANCES/g" "$yarn_props"
$SED "s#FLUO_HOME=.*#FLUO_HOME=$FLUO_HOME#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh
$SED "s#HADOOP_PREFIX=.*#HADOOP_PREFIX=$HADOOP_HOME#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh
$SED "s#ZOOKEEPER_HOME=.*#ZOOKEEPER_HOME=$ZOOKEEPER_HOME#g" "$FLUO_YARN_HOME"/conf/fluo-yarn-env.sh

"$FLUO_YARN_HOME"/lib/fetch.sh

stty sane

true
# fluo-yarn.sh
