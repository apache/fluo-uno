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

# Start: Resolve Script Directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
   impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
   SOURCE="$(readlink "$SOURCE")"
   [[ $SOURCE != /* ]] && SOURCE="$impl/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
script=$( basename "$SOURCE" )
# Stop: Resolve Script Directory

function config_hadoop() {
  cp $FLUO_DEV/conf/hadoop/* $HADOOP_PREFIX/etc/hadoop/
  $SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
  $SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
  $SED "s#YARN_LOGS#$HADOOP_PREFIX/logs#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
}

function config_zookeeper() {
  cp $FLUO_DEV/conf/zookeeper/* $ZOOKEEPER_HOME/conf/
  $SED "s#DATA_DIR#$DATA_DIR#g" $ZOOKEEPER_HOME/conf/zoo.cfg
}

function config_accumulo() {
  cp $ACCUMULO_HOME/conf/examples/2GB/standalone/* $ACCUMULO_HOME/conf/
  cp $FLUO_DEV/conf/accumulo/* $ACCUMULO_HOME/conf/
}

function config_fluo() {
  cp $FLUO_REPO/modules/distribution/src/main/config/* $FLUO_DEV/conf/fluo/
  FLUO_PROPS=$FLUO_DEV/conf/fluo/fluo.properties
  $SED "s/io.fluo.client.accumulo.instance=/io.fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" $FLUO_PROPS
  $SED "s/io.fluo.client.accumulo.user=/io.fluo.client.accumulo.user=$ACCUMULO_USER/g" $FLUO_PROPS
  $SED "s/io.fluo.client.accumulo.password=/io.fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" $FLUO_PROPS
  $SED "s/io.fluo.admin.accumulo.table=/io.fluo.admin.accumulo.table=$ACCUMULO_TABLE/g" $FLUO_PROPS
}

case "$1" in
hadoop)
  config_hadoop
	;;
zookeeper)
  config_zookeeper
	;;
accumulo)
  config_accumulo
	;;
fluo)
  config_fluo
	;;
all)
  config_hadoop
  config_zookeeper
  config_accumulo
  config_fluo
  ;;
*)
	echo -e "Usage: fluo-dev configure <argument>\n"
  echo -e "Possible arguments:\n"
  echo "  hadoop      Copies configuration to Hadoop"
  echo "  zookeeper   Copies configuration to Zookeeper"
  echo "  accumulo    Copies configuration to Accumulo"
  echo "  fluo        Copies configuration from Fluo repo to fluo-dev"
  echo "  all         Configures all of the above"
  exit 1
esac
