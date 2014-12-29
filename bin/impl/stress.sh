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

# stop if any command fails
set -e  

cd $FLUO_REPO
mvn install -DskipTests
cd modules/stress
mvn package assembly:single

JAR=$FLUO_REPO/modules/stress/target/fluo-stress-$FLUO_VERSION-jar-with-dependencies.jar
PROPS=$FLUO_HOME/conf/fluo.properties

# create splits
java -cp $JAR io.fluo.stress.trie.Split $PROPS 10 1000000

# gen numbers
$HADOOP_PREFIX/bin/hdfs dfs -rm -r /trie1 || true

YARN=$HADOOP_PREFIX/bin/yarn
$YARN jar $JAR io.fluo.stress.trie.Generate 1 50000 1000000 /trie1

# count unique
$YARN jar $JAR io.fluo.stress.trie.Unique /trie1

# load
$YARN jar $JAR io.fluo.stress.trie.Load $PROPS /trie1

# print
java -cp $JAR io.fluo.stress.trie.Print $PROPS
