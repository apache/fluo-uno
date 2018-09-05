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

pkill -f hadoop.hdfs
pkill -f hadoop.yarn

# stop if any command fails
set -e

verify_exist_hash "$HADOOP_TARBALL" "$HADOOP_HASH"

namenode_port=9870
if [[ $HADOOP_VERSION =~ ^2\..*$ ]]; then
  namenode_port=50070
  export HADOOP_PREFIX=$HADOOP_HOME
fi

print_to_console "Setting up Apache Hadoop $HADOOP_VERSION at $HADOOP_HOME"
print_to_console "    * NameNode status: http://localhost:$namenode_port/"
print_to_console "    * ResourceManager status: http://localhost:8088/"
print_to_console "    * view logs at $HADOOP_LOG_DIR"

rm -rf "$INSTALL"/hadoop-*
rm -f "$HADOOP_LOG_DIR"/*
rm -rf "$HADOOP_LOG_DIR"/application_*
rm -rf "$DATA_DIR"/hadoop
mkdir -p "$HADOOP_LOG_DIR"

tar xzf "$DOWNLOADS/$HADOOP_TARBALL" -C "$INSTALL"

hadoop_conf="$HADOOP_HOME"/etc/hadoop
cp "$UNO_HOME"/conf/hadoop/* "$hadoop_conf/"
$SED "s#UNO_HOST#$UNO_HOST#g" "$hadoop_conf/core-site.xml" "$hadoop_conf/hdfs-site.xml" "$hadoop_conf/yarn-site.xml"
$SED "s#DATA_DIR#$DATA_DIR#g" "$hadoop_conf/hdfs-site.xml" "$hadoop_conf/yarn-site.xml" "$hadoop_conf/mapred-site.xml"
$SED "s#HADOOP_LOG_DIR#$HADOOP_LOG_DIR#g" "$hadoop_conf/yarn-site.xml"
$SED "s#YARN_NM_MEM_MB#$YARN_NM_MEM_MB#g" "$hadoop_conf/yarn-site.xml"
$SED "s#YARN_NM_CPU_VCORES#$YARN_NM_CPU_VCORES#g" "$hadoop_conf/yarn-site.xml"

echo "export JAVA_HOME=$JAVA_HOME" >> "$hadoop_conf/hadoop-env.sh"
echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR" >> "$hadoop_conf/hadoop-env.sh"
if [[ $HADOOP_VERSION =~ ^2\..*$ ]]; then
  echo "export YARN_LOG_DIR=$HADOOP_LOG_DIR" >> "$hadoop_conf/yarn-env.sh"
fi

"$HADOOP_HOME"/bin/hdfs namenode -format
"$HADOOP_HOME"/sbin/start-dfs.sh
"$HADOOP_HOME"/sbin/start-yarn.sh

