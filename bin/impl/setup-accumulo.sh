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

if [[ -z "$ACCUMULO_REPO" ]]; then
  verify_exist_hash "$ACCUMULO_TARBALL" "$ACCUMULO_MD5"
fi
verify_exist_hash "$HADOOP_TARBALL" "$HADOOP_MD5"
verify_exist_hash "$ZOOKEEPER_TARBALL" "$ZOOKEEPER_MD5"
verify_exist_hash "$SPARK_TARBALL" "$SPARK_MD5"

hostname=$(hostname)
if [[ "$(grep -c "${hostname}" /etc/hosts)" -ge 1 ]]; then
  echo "Found ${hostname} in /etc/hosts."
else
  host "${hostname}" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "Found ${hostname} in DNS."
  else
    echo "ERROR - Your machine was unable to find its own hostname in /etc/hosts or by using 'host $hostname'."
    echo "This is an issue that can cause fluo-dev services (such as Hadoop) to not start up.  You should"
    echo "confirm that there is an entry in /etc/hosts or that /etc/resolv.conf is correct."
    exit 1
  fi
fi

"$FLUO_DEV"/bin/impl/kill.sh

# stop if any command fails
set -e

echo "Removing previous versions of Hadoop, Zookeeper, Accumulo & Spark"
rm -rf "$INSTALL"/accumulo-*
rm -rf "$INSTALL"/hadoop-*
rm -rf "$INSTALL"/zookeeper-*
rm -rf "$INSTALL"/spark-*

echo "Remove previous log dirs and recreate"
rm -f "$HADOOP_LOG_DIR"/*
rm -rf "$YARN_LOG_DIR"/application_*
rm -f "$YARN_LOG_DIR"/*
rm -f "$ACCUMULO_LOG_DIR"/*
rm -f "$ZOO_LOG_DIR"/*
rm -f "$LOGS_DIR"/spark/*
mkdir -p "$HADOOP_LOG_DIR"
mkdir -p "$YARN_LOG_DIR"
mkdir -p "$ACCUMULO_LOG_DIR"
mkdir -p "$ZOO_LOG_DIR"
mkdir -p "$LOGS_DIR"/spark

echo "Installing Hadoop, Zookeeper, Accumulo & Spark to $INSTALL"
tar xzf "$DOWNLOADS/$ACCUMULO_TARBALL" -C "$INSTALL"
tar xzf "$DOWNLOADS/$HADOOP_TARBALL" -C "$INSTALL"
tar xzf "$DOWNLOADS/$ZOOKEEPER_TARBALL" -C "$INSTALL"
tar xzf "$DOWNLOADS/$SPARK_TARBALL" -C "$INSTALL"

echo "Configuring..."
# configure hadoop
cp "$FLUO_DEV"/conf/hadoop/* "$HADOOP_PREFIX"/etc/hadoop/
cp "$SPARK_HOME"/lib/spark-"$SPARK_VERSION"-yarn-shuffle.jar "$HADOOP_PREFIX"/share/hadoop/yarn/lib/
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/hdfs-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/mapred-site.xml
$SED "s#YARN_LOGS#$YARN_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_MEM_MB#$YARN_NM_MEM_MB#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_CPU_VCORES#$YARN_NM_CPU_VCORES#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#\#export HADOOP_LOG_DIR=[^ ]*#export HADOOP_LOG_DIR=$HADOOP_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/hadoop-env.sh
$SED "s#YARN_LOG_DIR=[^ ]*#YARN_LOG_DIR=$YARN_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-env.sh

# configure zookeeper
cp "$FLUO_DEV"/conf/zookeeper/* "$ZOOKEEPER_HOME"/conf/
$SED "s#DATA_DIR#$DATA_DIR#g" "$ZOOKEEPER_HOME"/conf/zoo.cfg

# configure accumulo
cp "$ACCUMULO_HOME"/conf/examples/2GB/standalone/* "$ACCUMULO_HOME"/conf/
cp "$FLUO_DEV"/conf/accumulo/* "$ACCUMULO_HOME"/conf/
$SED "s#export ZOOKEEPER_HOME=[^ ]*#export ZOOKEEPER_HOME=$ZOOKEEPER_HOME#" "$ACCUMULO_HOME"/conf/accumulo-env.sh
$SED "s#export HADOOP_PREFIX=[^ ]*#export HADOOP_PREFIX=$HADOOP_PREFIX#" "$ACCUMULO_HOME"/conf/accumulo-env.sh
$SED "s#ACCUMULO_TSERVER_OPTS=.*#ACCUMULO_TSERVER_OPTS=\"-Xmx$ACCUMULO_TSERV_MEM -Xms$ACCUMULO_TSERV_MEM\"#" "$ACCUMULO_HOME"/conf/accumulo-env.sh
$SED "s#ACCUMULO_DCACHE_SIZE#$ACCUMULO_DCACHE_SIZE#" "$ACCUMULO_HOME"/conf/accumulo-site.xml
$SED "s#ACCUMULO_ICACHE_SIZE#$ACCUMULO_ICACHE_SIZE#" "$ACCUMULO_HOME"/conf/accumulo-site.xml
$SED "s#ACCUMULO_IMAP_SIZE#$ACCUMULO_IMAP_SIZE#" "$ACCUMULO_HOME"/conf/accumulo-site.xml
$SED "s#ACCUMULO_USE_NATIVE_MAP#$ACCUMULO_USE_NATIVE_MAP#" "$ACCUMULO_HOME"/conf/accumulo-site.xml
if [[ "$ACCUMULO_USE_NATIVE_MAP" == "true" ]]; then
  echo "Building Accumulo native map library..."
  "$ACCUMULO_HOME"/bin/build_native_library.sh
fi

# configure spark
cp "$FLUO_DEV"/conf/spark/* "$SPARK_HOME"/conf
$SED "s#DATA_DIR#$DATA_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$SPARK_HOME"/conf/spark-defaults.conf

echo "Starting Spark HistoryServer..."
rm -rf "$DATA_DIR"/spark
mkdir -p "$DATA_DIR"/spark/events
if [[ "$START_SPARK_HIST_SERVER" == "true" ]]; then
  export SPARK_LOG_DIR=$LOGS_DIR/spark
  "$SPARK_HOME"/sbin/start-history-server.sh
fi

echo "Starting Hadoop..."
rm -rf "$DATA_DIR"/hadoop
echo $HADOOP_LOG_DIR
"$HADOOP_PREFIX"/bin/hdfs namenode -format
"$HADOOP_PREFIX"/sbin/start-dfs.sh
"$HADOOP_PREFIX"/sbin/start-yarn.sh

echo "Starting Zookeeper..."
rm -rf "$DATA_DIR"/zookeeper
"$ZOOKEEPER_HOME"/bin/zkServer.sh start

echo "Starting Accumulo..."
"$HADOOP_PREFIX"/bin/hadoop fs -rm -r /accumulo 2> /dev/null || true
"$ACCUMULO_HOME"/bin/accumulo init --clear-instance-name --instance-name "$ACCUMULO_INSTANCE" --password "$ACCUMULO_PASSWORD"
"$ACCUMULO_HOME"/bin/start-all.sh
