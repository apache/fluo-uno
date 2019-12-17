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

pkill -f fluo\\.yarn
pkill -f MiniFluo
pkill -f accumulo\\.start
pkill -f hadoop\\.hdfs
pkill -f hadoop\\.yarn
pkill -f QuorumPeerMain

if [[ -d "$SPARK_HOME" ]]; then
  pkill -f org\\.apache\\.spark\\.deploy\\.history\\.HistoryServer
fi
if [[ -d "$INFLUXDB_HOME" ]]; then
  pkill -f influxdb
fi
if [[ -d "$GRAFANA_HOME" ]]; then
  pkill -f grafana-server
fi
if [[ -d "$PROXY_HOME" ]]; then
  pkill -f accumulo\\.proxy\\.Proxy
fi
