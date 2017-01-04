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

verify_exist_hash "$HADOOP_TARBALL" "$HADOOP_HASH"

if [[ "$OSTYPE" != "darwin"* ]]; then
  hostname=$(hostname)
  if [[ "$(grep -c "${hostname}" /etc/hosts)" -ge 1 ]]; then
    echo "Found ${hostname} in /etc/hosts."
  else
    host "${hostname}" &> /dev/null
    if [[ $? -eq 0 ]]; then
      echo "Found ${hostname} in DNS."
    else
      echo "ERROR - Your machine was unable to find its own hostname in /etc/hosts or by using 'host $hostname'."
      echo "This is an issue that can cause uno services (such as Hadoop) to not start up. You should"
      echo "confirm that there is an entry in /etc/hosts or that /etc/resolv.conf is correct."
      exit 1
    fi
  fi
fi

pkill -f hadoop.hdfs
pkill -f hadoop.yarn

# stop if any command fails
set -e

echo "Setting up Apache Hadoop at $HADOOP_PREFIX"

rm -rf "$INSTALL"/hadoop-*
rm -f "$HADOOP_LOG_DIR"/*
rm -rf "$YARN_LOG_DIR"/application_*
rm -f "$YARN_LOG_DIR"/*
rm -rf "$DATA_DIR"/hadoop
mkdir -p "$HADOOP_LOG_DIR"
mkdir -p "$YARN_LOG_DIR"

tar xzf "$DOWNLOADS/$HADOOP_TARBALL" -C "$INSTALL"

cp "$UNO_HOME"/conf/hadoop/* "$HADOOP_PREFIX"/etc/hadoop/
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/hdfs-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/mapred-site.xml
$SED "s#YARN_LOGS#$YARN_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_MEM_MB#$YARN_NM_MEM_MB#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_CPU_VCORES#$YARN_NM_CPU_VCORES#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-site.xml
$SED "s#\#export HADOOP_LOG_DIR=[^ ]*#export HADOOP_LOG_DIR=$HADOOP_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/hadoop-env.sh
$SED "s#YARN_LOG_DIR=[^ ]*#YARN_LOG_DIR=$YARN_LOG_DIR#g" "$HADOOP_PREFIX"/etc/hadoop/yarn-env.sh

"$HADOOP_PREFIX"/bin/hdfs namenode -format
"$HADOOP_PREFIX"/sbin/start-dfs.sh
"$HADOOP_PREFIX"/sbin/start-yarn.sh

echo "Apache Hadoop setup complete"
