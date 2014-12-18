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

pkill -f hadoop.hdfs.server
pkill -f hadoop.hdfs.tools
pkill -f hadoop.yarn.server
pkill -f accumulo.start

rm -rf $HADOOP_PREFIX/logs/*
rm -rf /tmp/fluo-dev-data/hadoop/data
rm -rf /tmp/fluo-dev-data/hadoop/name

$HADOOP_PREFIX/bin/hdfs namenode -format

$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
