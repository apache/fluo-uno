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

pkill -f accumulo.start

# stop if any command fails
set -e

if [[ -z "$ACCUMULO_REPO" ]]; then
  verify_exist_hash "$ACCUMULO_TARBALL" "$ACCUMULO_HASH"
fi

if [[ $1 != "--no-deps" ]]; then
  run_setup_script Hadoop
  run_setup_script ZooKeeper
fi

print_to_console "Setting up Apache Accumulo $ACCUMULO_VERSION at $ACCUMULO_HOME"
print_to_console "    * Accumulo Monitor: http://localhost:9995/"
print_to_console "    * view logs at $ACCUMULO_LOG_DIR"

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
  if [[ "$ACCUMULO_CRYPTO" == "true" ]]; then
    encrypt_key=$ACCUMULO_HOME/conf/data-encryption.key
    openssl rand -out $encrypt_key 32
    echo "instance.crypto.opts.key.provider=uri" >> "$accumulo_conf"
    echo "instance.crypto.opts.key.location=file://$encrypt_key" >> "$accumulo_conf"
    echo "instance.crypto.service=org.apache.accumulo.core.security.crypto.impl.AESCryptoService" >> "$accumulo_conf"
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

if [[ "$1" == "--with-metrics" ]]; then
  metrics_props=hadoop-metrics2-accumulo.properties
  cp "$conf"/templates/"$metrics_props" "$conf"/
  $SED "/accumulo.sink.graphite/d" "$conf"/"$metrics_props"
  {
    echo "accumulo.sink.graphite.class=org.apache.hadoop.metrics2.sink.GraphiteSink"
    echo "accumulo.sink.graphite.server_host=localhost"
    echo "accumulo.sink.graphite.server_port=2004"
    echo "accumulo.sink.graphite.metrics_prefix=accumulo"
  } >> "$conf"/"$metrics_props"
  run_setup_script Metrics
fi

if [[ "$ACCUMULO_USE_NATIVE_MAP" == "true" ]]; then
  if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
    "$ACCUMULO_HOME"/bin/build_native_library.sh
  else
    "$ACCUMULO_HOME"/bin/accumulo-util build-native
  fi
fi

"$HADOOP_HOME"/bin/hadoop fs -rm -r /accumulo 2> /dev/null || true
"$ACCUMULO_HOME"/bin/accumulo init --clear-instance-name --instance-name "$ACCUMULO_INSTANCE" --password "$ACCUMULO_PASSWORD"

if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  "$ACCUMULO_HOME"/bin/start-all.sh
else
  "$ACCUMULO_HOME"/bin/accumulo-cluster start
fi

