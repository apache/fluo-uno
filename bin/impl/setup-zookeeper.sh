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

verify_exist_hash "$ZOOKEEPER_TARBALL" "$ZOOKEEPER_HASH"

pkill -f QuorumPeerMain

# stop if any command fails
set -e

print_to_console "Setting up Apache ZooKeeper at $ZOOKEEPER_HOME"
print_to_console "    * view logs at $ZOO_LOG_DIR"

rm -rf "$INSTALL"/zookeeper-*
rm -f "$ZOO_LOG_DIR"/*
mkdir -p "$ZOO_LOG_DIR"

tar xzf "$DOWNLOADS/$ZOOKEEPER_TARBALL" -C "$INSTALL"

cp "$UNO_HOME"/conf/zookeeper/* "$ZOOKEEPER_HOME"/conf/
$SED "s#DATA_DIR#$DATA_DIR#g" "$ZOOKEEPER_HOME"/conf/zoo.cfg

rm -rf "$DATA_DIR"/zookeeper
"$ZOOKEEPER_HOME"/bin/zkServer.sh start

