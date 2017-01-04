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

if [[ ! -z "$(pgrep -f accumulo\\.start)" ]]; then
	if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
	  "$ACCUMULO_HOME"/bin/stop-all.sh
	else
	  "$ACCUMULO_HOME"/bin/accumulo-cluster stop
	fi
fi

if [[ ! -z "$(pgrep -f hadoop\\.yarn)" ]]; then
	"$HADOOP_PREFIX"/sbin/stop-yarn.sh
fi

if [[ ! -z "$(pgrep -f hadoop\\.hdfs)" ]]; then
	"$HADOOP_PREFIX"/sbin/stop-dfs.sh
fi

if [[ ! -z "$(pgrep -f QuorumPeerMain)" ]]; then
	"$ZOOKEEPER_HOME"/bin/zkServer.sh stop
fi
