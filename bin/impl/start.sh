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

case "$1" in
  accumulo)
    check_dirs ACCUMULO_HOME

    if [[ "$2" != "--no-deps" ]]; then
      check_dirs ZOOKEEPER_HOME HADOOP_HOME

      tmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"
      if [[ -z "$tmp" ]]; then
        "$ZOOKEEPER_HOME"/bin/zkServer.sh start
      else echo "ZooKeeper   already running at: $tmp"
      fi

      tmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
      if [[ -z "$tmp" ]]; then
        "$HADOOP_HOME"/sbin/start-dfs.sh
      else echo "Hadoop DFS  already running at: $tmp"  
      fi
      
      tmp="$(pgrep -f hadoop\\.yarn | tr '\n' ' ')"
      if [[ -z "$tmp" ]]; then
        "$HADOOP_HOME"/sbin/start-yarn.sh
      else echo "Hadoop Yarn already running at: $tmp"  
      fi
    fi

    tmp="$(pgrep -f accumulo\\.start | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
        "$ACCUMULO_HOME"/bin/start-all.sh
      else
        "$ACCUMULO_HOME"/bin/accumulo-cluster start
      fi
    else echo "Accumulo    already running at: $tmp"  
    fi
    ;;
  hadoop)
    check_dirs HADOOP_HOME
    
    tmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      "$HADOOP_HOME"/sbin/start-dfs.sh
    else echo "Hadoop DFS  already running at: $tmp"  
    fi

    tmp="$(pgrep -f hadoop\\.yarn | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      "$HADOOP_HOME"/sbin/start-yarn.sh
    else echo "Hadoop Yarn already running at: $tmp"  
    fi
    ;;
  zookeeper)
    check_dirs ZOOKEEPER_HOME

    tmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      "$ZOOKEEPER_HOME"/bin/zkServer.sh start
    else echo "ZooKeeper   already running at: $tmp"
    fi
    ;;
  metrics)
    tmp="$(pgrep -f influxd | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      "$INFLUXDB_HOME"/bin/influxd -config "$INFLUXDB_HOME"/influxdb.conf &> "$LOGS_DIR"/metrics/influxdb.log &
    else echo "InfluxDB already running at: $tmp"
    fi
    tmp="$(pgrep -f grafana-server | tr '\n' ' ')"
    if [[ -z "$tmp" ]]; then
      "$GRAFANA_HOME"/bin/grafana-server -homepath="$GRAFANA_HOME" 2> /dev/null &
    else echo "Grafana already running at: $tmp"
    fi
    ;;

  # NYI
  # fluo)
  #   
  #   ;;
  # spark)
  #   
  #   ;;

  *)
    echo "Usage: uno start <component> [--no-deps]"
    echo -e "\nPossible components:\n"
    echo "    accumulo   Start Apache Accumulo plus dependencies: Hadoop, ZooKeeper"
    echo "    hadoop     Start Apache Hadoop"
    echo "    zookeeper  Start Apache ZooKeeper"
    echo "    metrics    Start InfluxDB and Grafana"
    echo "Options:"
    echo "    --no-deps  Dependencies will start unless this option is specified. Only works for accumulo component."
    exit 1
    ;;
  esac
