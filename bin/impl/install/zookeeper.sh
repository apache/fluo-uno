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

# shellcheck source=bin/impl/util.sh
source "$UNO_HOME"/bin/impl/util.sh

pkill -f QuorumPeerMain

# stop if any command fails
set -e
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND"' ERR

verify_exist_hash "$ZOOKEEPER_TARBALL" "$ZOOKEEPER_HASH"

print_to_console "Installing Apache ZooKeeper $ZOOKEEPER_VERSION at $ZOOKEEPER_HOME"

rm -rf "${INSTALL:?}"/*zookeeper-*
rm -f "${ZOO_LOG_DIR:?}"/*
rm -rf "${DATA_DIR:?}"/zookeeper
mkdir -p "$ZOO_LOG_DIR"

tar xzf "$DOWNLOADS/$ZOOKEEPER_TARBALL" -C "$INSTALL"

cp "$UNO_HOME"/conf/zookeeper/* "$ZOOKEEPER_HOME"/conf/
$SED "s#DATA_DIR#$DATA_DIR#g" "$ZOOKEEPER_HOME"/conf/zoo.cfg

true
# zookeeper.sh
