#!/bin/bash

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

if [ ! -f "$DOWNLOADS/$ACCUMULO_TARBALL" ]; then
  echo "Accumulo tarball $ACCUMULO_TARBALL does not exists in downloads/"
  exit 1
fi

if [ ! -f "$DOWNLOADS/$HADOOP_TARBALL" ]; then
  echo "Hadoop tarball $HADOOP_TARBALL does not exists in downloads/"
  exit 1
fi

if [ ! -f "$DOWNLOADS/$ZOOKEEPER_TARBALL" ]; then
  echo "Zookeeper tarball $ZOOKEEPER_TARBALL does not exists in downloads/"
  exit 1
fi

$FLUO_DEV/bin/impl/kill.sh

echo "Removing previous versions of Hadoop, Zookeeper & Accumulo"
rm -rf $INSTALL/accumulo-*
rm -rf $INSTALL/hadoop-*
rm -rf $INSTALL/zookeeper-*

echo "Installing Hadoop, Zookeeper & Accumulo to $INSTALL"
tar xzf $DOWNLOADS/$ACCUMULO_TARBALL -C $INSTALL
tar xzf $DOWNLOADS/$HADOOP_TARBALL -C $INSTALL
tar xzf $DOWNLOADS/$ZOOKEEPER_TARBALL -C $INSTALL

echo "Configuring..."
# configure hadoop
cp $FLUO_DEV/conf/hadoop/* $HADOOP_PREFIX/etc/hadoop/
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
$SED "s#YARN_LOGS#$HADOOP_PREFIX/logs#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# configure zookeeper
cp $FLUO_DEV/conf/zookeeper/* $ZOOKEEPER_HOME/conf/
$SED "s#DATA_DIR#$DATA_DIR#g" $ZOOKEEPER_HOME/conf/zoo.cfg

# configure accumulo
cp $ACCUMULO_HOME/conf/examples/2GB/standalone/* $ACCUMULO_HOME/conf/
cp $FLUO_DEV/conf/accumulo/* $ACCUMULO_HOME/conf/
$SED "s#export ZOOKEEPER_HOME=[^ ]*#export ZOOKEEPER_HOME=$ZOOKEEPER_HOME#" $ACCUMULO_HOME/conf/accumulo-env.sh
$SED "s#export HADOOP_PREFIX=[^ ]*#export HADOOP_PREFIX=$HADOOP_PREFIX#" $ACCUMULO_HOME/conf/accumulo-env.sh

echo "Starting Hadoop..."
rm -rf $HADOOP_PREFIX/logs/*
rm -rf $DATA_DIR/hadoop
$HADOOP_PREFIX/bin/hdfs namenode -format
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh

echo "Starting Zookeeper..."
rm $ZOOKEEPER_HOME/zookeeper.out
rm -rf $DATA_DIR/zookeeper
export ZOO_LOG_DIR=$ZOOKEEPER_HOME
$ZOOKEEPER_HOME/bin/zkServer.sh start

echo "Starting Accumulo..."
rm -f $ACCUMULO_HOME/logs/*
$HADOOP_PREFIX/bin/hadoop fs -rm -r /accumulo 2> /dev/null
$ACCUMULO_HOME/bin/accumulo init --clear-instance-name --instance-name $ACCUMULO_INSTANCE --password $ACCUMULO_PASSWORD
$ACCUMULO_HOME/bin/start-all.sh
