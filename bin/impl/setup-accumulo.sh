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

if [[ -z "$ACCUMULO_REPO" ]]; then
  verify_exist_hash "$ACCUMULO_TARBALL" "$ACCUMULO_HASH"
fi

if [[ $1 != "--no-deps" ]]; then
  "$UNO_HOME"/bin/impl/setup-hadoop.sh
  "$UNO_HOME"/bin/impl/setup-zookeeper.sh
fi

pkill -f accumulo.start

# stop if any command fails
set -e

echo "Setting up Apache Accumulo at $ACCUMULO_HOME"

rm -rf "$INSTALL"/accumulo-*
rm -f "$ACCUMULO_LOG_DIR"/*
mkdir -p "$ACCUMULO_LOG_DIR"

tar xzf "$DOWNLOADS/$ACCUMULO_TARBALL" -C "$INSTALL"

conf=$ACCUMULO_HOME/conf

if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  cp "$conf"/examples/2GB/standalone/* "$conf"/
  $SED "s#localhost#$UNO_HOST#" "$conf/slaves"
  cp "$UNO_HOME"/conf/accumulo/accumulo-site-1.0.xml "$conf"/accumulo-site.xml
else
  "$ACCUMULO_HOME"/bin/accumulo-cluster create-config
  $SED "s#localhost#$UNO_HOST#" "$conf/tservers"
  cp "$UNO_HOME"/conf/accumulo/accumulo-site-2.0.xml "$conf"/accumulo-site.xml
fi
$SED "s#localhost#$UNO_HOST#" "$conf/masters" "$conf/monitor" "$conf/gc"
$SED "s#export ZOOKEEPER_HOME=[^ ]*#export ZOOKEEPER_HOME=$ZOOKEEPER_HOME#" "$conf"/accumulo-env.sh
$SED "s#export HADOOP_PREFIX=[^ ]*#export HADOOP_PREFIX=$HADOOP_PREFIX#" "$conf"/accumulo-env.sh
$SED "s#export ACCUMULO_LOG_DIR=[^ ]*#export ACCUMULO_LOG_DIR=$ACCUMULO_LOG_DIR#" "$conf"/accumulo-env.sh
if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  $SED "s#ACCUMULO_TSERVER_OPTS=.*#ACCUMULO_TSERVER_OPTS=\"-Xmx$ACCUMULO_TSERV_MEM -Xms$ACCUMULO_TSERV_MEM\"#" "$conf"/accumulo-env.sh
else
  $SED "s#tserver).*#tserver) JAVA_OPTS=\(\"\$\{JAVA_OPTS\[\@\]\}\" '-Xmx$ACCUMULO_TSERV_MEM' '-Xms$ACCUMULO_TSERV_MEM\'\) ;;#" "$conf"/accumulo-env.sh
fi
$SED "s#ACCUMULO_DCACHE_SIZE#$ACCUMULO_DCACHE_SIZE#" "$conf"/accumulo-site.xml
$SED "s#ACCUMULO_ICACHE_SIZE#$ACCUMULO_ICACHE_SIZE#" "$conf"/accumulo-site.xml
$SED "s#ACCUMULO_IMAP_SIZE#$ACCUMULO_IMAP_SIZE#" "$conf"/accumulo-site.xml
$SED "s#ACCUMULO_USE_NATIVE_MAP#$ACCUMULO_USE_NATIVE_MAP#" "$conf"/accumulo-site.xml
$SED "s#UNO_HOST#$UNO_HOST#" "$conf"/accumulo-site.xml

if [[ "$ACCUMULO_USE_NATIVE_MAP" == "true" ]]; then
  if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
    "$ACCUMULO_HOME"/bin/build_native_library.sh
  else
    "$ACCUMULO_HOME"/bin/accumulo-util build-native
  fi
fi

"$HADOOP_PREFIX"/bin/hadoop fs -rm -r /accumulo 2> /dev/null || true
"$ACCUMULO_HOME"/bin/accumulo init --clear-instance-name --instance-name "$ACCUMULO_INSTANCE" --password "$ACCUMULO_PASSWORD"

if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  "$ACCUMULO_HOME"/bin/start-all.sh
else
  "$ACCUMULO_HOME"/bin/accumulo-cluster start
fi

echo "Apache Accumulo setup complete"
