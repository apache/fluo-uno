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

echo "Killing fluo (if running)"
$FLUO_DEV/bin/impl/kill.sh all

echo "Removing previously installed versions of Accumulo, Hadoop, & Zookeeper"
rm -rf $SOFTWARE/accumulo-*
rm -rf $SOFTWARE/hadoop-*
rm -rf $SOFTWARE/zookeeper-*

echo "Installing Accumulo, Hadoop, & Zookeeper to $SOFTWARE"
tar xzf $DOWNLOADS/$ACCUMULO_TARBALL -C $SOFTWARE
tar xzf $DOWNLOADS/$HADOOP_TARBALL -C $SOFTWARE
tar xzf $DOWNLOADS/$ZOOKEEPER_TARBALL -C $SOFTWARE
