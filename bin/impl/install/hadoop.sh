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

source "$UNO_HOME"/bin/impl/util.sh

pkill -f hadoop.hdfs
pkill -f hadoop.yarn

# stop if any command fails
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

verify_exist_hash "$HADOOP_TARBALL" "$HADOOP_HASH"

print_to_console "Installing Apache Hadoop $HADOOP_VERSION at $HADOOP_HOME"

rm -rf "$INSTALL"/hadoop-*
rm -rf "$HADOOP_LOG_DIR"/*
rm -rf "$DATA_DIR"/hadoop
mkdir -p "$HADOOP_LOG_DIR"

tar xzf "$DOWNLOADS/$HADOOP_TARBALL" -C "$INSTALL"

hadoop_conf="$HADOOP_HOME"/etc/hadoop
cp "$UNO_HOME"/conf/hadoop/common/* "$hadoop_conf/"
if [[ $HADOOP_VERSION =~ ^2\..*$ ]]; then
  cp "$UNO_HOME"/conf/hadoop/2/* "$hadoop_conf/"
else
  cp "$UNO_HOME"/conf/hadoop/3/* "$hadoop_conf/"
  # need the following for Java 11, because Hadoop doesn't include it
  # Using maven-dependency-plugin version 3.1.1 explicitly, because some older
  # versions require to be executed within a POM project
  mvn org.apache.maven.plugins:maven-dependency-plugin:3.1.1:copy \
    -Dartifact=javax.activation:javax.activation-api:1.2.0 \
    -DoutputDirectory="$HADOOP_HOME/share/hadoop/common/lib/"
fi

$SED "s#UNO_HOST#$UNO_HOST#g" "$hadoop_conf/core-site.xml" "$hadoop_conf/hdfs-site.xml" "$hadoop_conf/yarn-site.xml"
$SED "s#DATA_DIR#$DATA_DIR#g" "$hadoop_conf/hdfs-site.xml" "$hadoop_conf/yarn-site.xml" "$hadoop_conf/mapred-site.xml"
$SED "s#HADOOP_HOME#$HADOOP_HOME#g" "$hadoop_conf/mapred-site.xml"
$SED "s#HADOOP_LOG_DIR#$HADOOP_LOG_DIR#g" "$hadoop_conf/yarn-site.xml"
$SED "s#YARN_NM_MEM_MB#$YARN_NM_MEM_MB#g" "$hadoop_conf/yarn-site.xml"
$SED "s#YARN_NM_CPU_VCORES#$YARN_NM_CPU_VCORES#g" "$hadoop_conf/yarn-site.xml"

echo "export JAVA_HOME=$JAVA_HOME" >> "$hadoop_conf/hadoop-env.sh"
echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR" >> "$hadoop_conf/hadoop-env.sh"
echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" >> "$hadoop_conf/hadoop-env.sh"
if [[ $HADOOP_VERSION =~ ^2\..*$ ]]; then
  echo "export YARN_LOG_DIR=$HADOOP_LOG_DIR" >> "$hadoop_conf/yarn-env.sh"
fi
