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

pkill -f accumulo.start

# stop if any command fails
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

[[ -z $ACCUMULO_REPO ]] && verify_exist_hash "$ACCUMULO_TARBALL" "$ACCUMULO_HASH"
if [[ $1 != '--no-deps' ]]; then
  install_component Hadoop
  install_component ZooKeeper
fi

print_to_console "Installing Apache Accumulo $ACCUMULO_VERSION at $ACCUMULO_HOME"

rm -rf "$INSTALL"/accumulo-*
rm -f "$ACCUMULO_LOG_DIR"/*
mkdir -p "$ACCUMULO_LOG_DIR"

tar xzf "$DOWNLOADS/$ACCUMULO_TARBALL" -C "$INSTALL"

conf=$ACCUMULO_HOME/conf

cp "$UNO_HOME"/conf/accumulo/common/* "$conf"
if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  accumulo_conf=$conf/accumulo-site.xml
  cp "$conf"/examples/2GB/standalone/* "$conf"/
  $SED "s#localhost#$UNO_HOST#" "$conf/slaves"
  cp "$UNO_HOME"/conf/accumulo/1/* "$conf"
  $SED "s#export HADOOP_PREFIX=[^ ]*#export HADOOP_PREFIX=$HADOOP_HOME#" "$conf"/accumulo-env.sh
  $SED "s#ZOOKEEPER_HOME#ZOOKEEPER_HOME/lib#" "$accumulo_conf"
  $SED "s#-maxdepth 1#-maxdepth 2#" "$ACCUMULO_HOME"/bin/start-all.sh
else
  accumulo_conf=$conf/accumulo.properties
  cp "$UNO_HOME"/conf/accumulo/2/* "$conf"
  "$ACCUMULO_HOME"/bin/accumulo-cluster create-config
  $SED "s#localhost#$UNO_HOST#" "$conf/tservers"
  $SED "s#export HADOOP_HOME=[^ ]*#export HADOOP_HOME=$HADOOP_HOME#" "$conf"/accumulo-env.sh
  $SED "s#instance[.]name=#instance.name=$ACCUMULO_INSTANCE#" "$conf"/accumulo-client.properties
  $SED "s#instance[.]zookeepers=localhost:2181#instance.zookeepers=$UNO_HOST:2181#" "$conf"/accumulo-client.properties
  $SED "s#auth[.]principal=#auth.principal=$ACCUMULO_USER#" "$conf"/accumulo-client.properties
  $SED "s#auth[.]token=#auth.token=$ACCUMULO_PASSWORD#" "$conf"/accumulo-client.properties
  if [[ $ACCUMULO_VERSION =~ ^2\.0\.0.*$ ]]; then
    # shellcheck disable=SC2016
    $SED 's#:[$][{]ZOOKEEPER_HOME[}]/[*]:#:${ZOOKEEPER_HOME}/*:${ZOOKEEPER_HOME}/lib/*:#' "$conf"/accumulo-env.sh
  fi
fi
$SED "s#localhost#$UNO_HOST#" "$conf/masters" "$conf/monitor" "$conf/gc"
$SED "s#export ZOOKEEPER_HOME=[^ ]*#export ZOOKEEPER_HOME=$ZOOKEEPER_HOME#" "$conf"/accumulo-env.sh
$SED "s#export ACCUMULO_LOG_DIR=[^ ]*#export ACCUMULO_LOG_DIR=$ACCUMULO_LOG_DIR#" "$conf"/accumulo-env.sh
if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  $SED "s#ACCUMULO_TSERVER_OPTS=.*#ACCUMULO_TSERVER_OPTS=\"-Xmx$ACCUMULO_TSERV_MEM -Xms$ACCUMULO_TSERV_MEM\"#" "$conf"/accumulo-env.sh
else
  $SED "s#tserver).*#tserver) JAVA_OPTS=\(\"\$\{JAVA_OPTS\[\@\]\}\" '-Xmx$ACCUMULO_TSERV_MEM' '-Xms$ACCUMULO_TSERV_MEM\'\) ;;#" "$conf"/accumulo-env.sh
fi
$SED "s#ACCUMULO_DCACHE_SIZE#$ACCUMULO_DCACHE_SIZE#" "$accumulo_conf"
$SED "s#ACCUMULO_ICACHE_SIZE#$ACCUMULO_ICACHE_SIZE#" "$accumulo_conf"
$SED "s#ACCUMULO_IMAP_SIZE#$ACCUMULO_IMAP_SIZE#" "$accumulo_conf"
$SED "s#ACCUMULO_USE_NATIVE_MAP#$ACCUMULO_USE_NATIVE_MAP#" "$accumulo_conf"
$SED "s#UNO_HOST#$UNO_HOST#" "$accumulo_conf"

it_props="$conf/accumulo-it.properties"
$SED "s#ACCUMULO_USER#$ACCUMULO_USER#" "$it_props"
$SED "s#ACCUMULO_PASSWORD#$ACCUMULO_PASSWORD#" "$it_props"
$SED "s#UNO_HOST#$UNO_HOST#" "$it_props"
$SED "s#ACCUMULO_INSTANCE#$ACCUMULO_INSTANCE#" "$it_props"
$SED "s#HADOOP_CONF_DIR#$HADOOP_CONF_DIR#" "$it_props"
$SED "s#ACCUMULO_HOME#$ACCUMULO_HOME#" "$it_props"

if [[ $ACCUMULO_USE_NATIVE_MAP == 'true' ]]; then
  if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
    "$ACCUMULO_HOME"/bin/build_native_library.sh
  else
    "$ACCUMULO_HOME"/bin/accumulo-util build-native
  fi
fi

