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

: "${bin:?"'\$bin' should be set by 'uno' script"}"

# shellcheck source=bin/impl/util.sh
source "$bin"/impl/util.sh

function uno_install_main() {
  case "$1" in
    accumulo|hadoop|fluo|fluo-yarn|zookeeper)
      if install_component "$@"; then
        echo "Installation of $1 complete."
      else
        echo "Installation of $1 failed!"
        return 1
      fi
      ;;
    *)
      print_cmd_usage 'install' 'Installs'
      return 1
      ;;
  esac
}

function uno_run_main() {
  [[ -n $LOGS_DIR ]] && rm -f "$LOGS_DIR"/setup/*.{out,err}
  echo "Running $1 (detailed logs in $LOGS_DIR/setup)..."
  save_console_fd
  case "$1" in
    accumulo|hadoop|fluo|fluo-yarn|zookeeper)
      if run_component "$@"; then
        echo "Running $1 complete."
      else
        echo "Running $1 failed!"
        return 1
      fi
      ;;
    *)
      print_cmd_usage 'run' 'Runs'
      return 1
      ;;
  esac
}

function uno_setup_main() {
  [[ -n $LOGS_DIR ]] && rm -f "$LOGS_DIR"/setup/*.{out,err}
  echo "Setting up $1 (detailed logs in $LOGS_DIR/setup)..."
  save_console_fd
  case "$1" in
    accumulo|hadoop|fluo|fluo-yarn|zookeeper)
      if setup_component "$@"; then
        echo "Setup of $1 complete."
      else
        echo "Setup of $1 failed!"
        return 1
      fi
      ;;
    *)
      print_cmd_usage 'setup' 'Sets up'
      return 1
      ;;
  esac
}

function uno_kill_main() {
  pkill -f fluo\\.yarn
  pkill -f MiniFluo
  pkill -f accumulo\\.start
  pkill -f hadoop\\.hdfs
  pkill -f hadoop\\.yarn
  pkill -f QuorumPeerMain
  [[ -d $SPARK_HOME ]] && pkill -f org\\.apache\\.spark\\.deploy\\.history\\.HistoryServer
  [[ -d $INFLUXDB_HOME ]] && pkill -f influxdb
  [[ -d $GRAFANA_HOME ]] && pkill -f grafana-server
  [[ -d $PROXY_HOME ]] && pkill -f accumulo\\.proxy\\.Proxy
  return 0
}

function uno_env_main() {
  if [[ -n $1 && $1 != '--vars' && $1 != '--paths' ]]; then
    echo "Unrecognized env option '$1'"
    return 1
  fi
  if [[ -z $1 || $1 == '--vars' ]]; then
    echo "export HADOOP_HOME=\"$HADOOP_HOME\""
    [[ $HADOOP_VERSION =~ ^2\..*$ ]] && echo "export HADOOP_PREFIX=\"$HADOOP_HOME\""
    echo "export HADOOP_CONF_DIR=\"$HADOOP_CONF_DIR\""
    echo "export ZOOKEEPER_HOME=\"$ZOOKEEPER_HOME\""
    echo "export SPARK_HOME=\"$SPARK_HOME\""
    echo "export ACCUMULO_HOME=\"$ACCUMULO_HOME\""
    echo "export FLUO_HOME=\"$FLUO_HOME\""
    echo "export FLUO_YARN_HOME=\"$FLUO_YARN_HOME\""
  fi
  if [[ -z $1 || $1 == '--paths' ]]; then
    echo -n "export PATH=\"\$PATH:$UNO_HOME/bin:$HADOOP_HOME/bin:$ZOOKEEPER_HOME/bin:$ACCUMULO_HOME/bin"
    [[ -d "$SPARK_HOME" ]]     && echo -n ":$SPARK_HOME/bin"
    [[ -d "$FLUO_HOME" ]]      && echo -n ":$FLUO_HOME/bin"
    [[ -d "$FLUO_YARN_HOME" ]] && echo -n ":$FLUO_YARN_HOME/bin"
    [[ -d "$INFLUXDB_HOME" ]]  && echo -n ":$INFLUXDB_HOME/bin"
    [[ -d "$GRAFANA_HOME" ]]   && echo -n ":$GRAFANA_HOME/bin"
    echo '"'
  fi
}

function uno_version_main() {
  case "$1" in
    hadoop) echo -n "$HADOOP_VERSION" ;;
    zookeeper) echo -n "$ZOOKEEPER_VERSION" ;;
    accumulo) echo -n "$ACCUMULO_VERSION" ;;
    fluo) echo -n "$FLUO_VERSION" ;;
    fluo-yarn) echo -n "$FLUO_YARN_VERSION" ;;
    spark) echo -n "$SPARK_VERSION" ;;
    influxdb) echo -n "$INFLUXDB_VERSION" ;;
    grafana) echo -n "$GRAFANA_VERSION" ;;
    *)
      echo "You must specify a valid depedency (i.e hadoop, zookeeper, accumulo, etc)"
      return 1
      ;;
  esac
}

function uno_start_main() {
  case "$1" in
    accumulo)
      check_dirs ACCUMULO_HOME || return 1

      if [[ $2 != '--no-deps' ]]; then
        check_dirs ZOOKEEPER_HOME HADOOP_HOME || return 1

        tmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"
        if [[ -z $tmp ]]; then
          "$ZOOKEEPER_HOME"/bin/zkServer.sh start
        else echo "ZooKeeper   already running at: $tmp"
        fi

        tmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
        if [[ -z $tmp ]]; then
          "$HADOOP_HOME"/sbin/start-dfs.sh
        else echo "Hadoop DFS  already running at: $tmp"
        fi

        tmp="$(pgrep -f hadoop\\.yarn | tr '\n' ' ')"
        if [[ -z $tmp ]]; then
          "$HADOOP_HOME"/sbin/start-yarn.sh
        else echo "Hadoop Yarn already running at: $tmp"
        fi
      fi

      tmp="$(pgrep -f accumulo\\.start | tr '\n' ' ')"
      if [[ -z $tmp ]]; then
        if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
          "$ACCUMULO_HOME"/bin/start-all.sh
        else
          "$ACCUMULO_HOME"/bin/accumulo-cluster start
        fi
      else echo "Accumulo    already running at: $tmp"
      fi
      ;;
    hadoop)
      check_dirs HADOOP_HOME || return 1

      tmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
      if [[ -z $tmp ]]; then
        "$HADOOP_HOME"/sbin/start-dfs.sh
      else echo "Hadoop DFS  already running at: $tmp"
      fi

      tmp="$(pgrep -f hadoop\\.yarn | tr '\n' ' ')"
      if [[ -z $tmp ]]; then
        "$HADOOP_HOME"/sbin/start-yarn.sh
      else echo "Hadoop Yarn already running at: $tmp"
      fi
      ;;
    zookeeper)
      check_dirs ZOOKEEPER_HOME || return 1

      tmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"
      if [[ -z $tmp ]]; then
        "$ZOOKEEPER_HOME"/bin/zkServer.sh start
      else echo "ZooKeeper   already running at: $tmp"
      fi
      ;;
    *)
      cat <<EOF
Usage: uno start <component> [--no-deps]

Possible components:

    accumulo   Start Apache Accumulo plus dependencies: Hadoop, ZooKeeper
    hadoop     Start Apache Hadoop
    zookeeper  Start Apache ZooKeeper

Options:
    --no-deps  Dependencies will start unless this option is specified. Only works for accumulo component.
EOF
      return 1
      ;;
  esac
}

function uno_stop_main() {
  case "$1" in
    accumulo)
      check_dirs ACCUMULO_HOME || return 1

      if pgrep -f accumulo\\.start >/dev/null; then
        if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
          "$ACCUMULO_HOME"/bin/stop-all.sh
        else
          "$ACCUMULO_HOME"/bin/accumulo-cluster stop
        fi
      fi

      if [[ $2 != "--no-deps" ]]; then
        check_dirs ZOOKEEPER_HOME HADOOP_HOME || return 1
        pgrep -f hadoop\\.yarn >/dev/null && "$HADOOP_HOME"/sbin/stop-yarn.sh
        pgrep -f hadoop\\.hdfs >/dev/null && "$HADOOP_HOME"/sbin/stop-dfs.sh
        pgrep -f QuorumPeerMain >/dev/null && "$ZOOKEEPER_HOME"/bin/zkServer.sh stop
      fi
      ;;
    hadoop)
      check_dirs HADOOP_HOME || return 1
      pgrep -f hadoop\\.yarn >/dev/null && "$HADOOP_HOME"/sbin/stop-yarn.sh
      pgrep -f hadoop\\.hdfs >/dev/null && "$HADOOP_HOME"/sbin/stop-dfs.sh
      ;;
    zookeeper)
      check_dirs ZOOKEEPER_HOME || return 1
      pgrep -f QuorumPeerMain >/dev/null && "$ZOOKEEPER_HOME"/bin/zkServer.sh stop
      ;;
    *)
      cat <<EOF
Usage: uno stop <component> [--no-deps]

Possible components:

    accumulo   Stop Apache Accumulo plus dependencies: Hadoop, ZooKeeper
    hadoop     Stop Apache Hadoop
    zookeeper  Stop Apache ZooKeeper

Options:
    --no-deps  Dependencies will stop unless this option is specified. Only works for accumulo component.
EOF
      return 1
      ;;
  esac
}

function uno_status_main() {
  # shellcheck disable=SC2009
  atmp="$(pgrep -f accumulo\\.start -a | awk '{pid = $1;for(i=1;i<=NF;i++)if($i=="org.apache.accumulo.start.Main")print $(i+1) "("pid")"}' | tr '\n' ' ')"
  # shellcheck disable=SC2009
  htmp="$(pgrep -f hadoop\\. -a | tr '.' ' ' | awk '{print $NF "(" $1 ")"}' | tr '\n' ' ')"
  ztmp="$(pgrep -f QuorumPeerMain | awk '{print "zoo(" $1 ")"}' | tr '\n' ' ')"

  if [[ -n $atmp || -n $ztmp || -n $htmp ]]; then
    [[ -n $atmp ]] && echo "Accumulo processes running: $atmp"
    [[ -n $ztmp ]] && echo "ZooKeeper processes running: $ztmp"
    [[ -n $htmp ]] && echo "Hadoop processes running: $htmp"
  else
    echo "No components running."
  fi
}

function uno_ashell_main() {
  check_dirs ACCUMULO_HOME || return 1
  "$ACCUMULO_HOME"/bin/accumulo shell -u "$ACCUMULO_USER" -p "$ACCUMULO_PASSWORD" "$@"
}

function uno_zk_main() {
  check_dirs ZOOKEEPER_HOME  || return 1
  "$ZOOKEEPER_HOME"/bin/zkCli.sh "$@"
}

function uno_fetch_main() {
  hash mvn 2>/dev/null || { echo >&2 "Maven must be installed & on PATH. Aborting."; return 1; }
  hash wget 2>/dev/null || { echo >&2 "wget must be installed & on PATH. Aborting."; return 1; }
  if [[ "$1" == "all" ]]; then
    "$bin"/impl/fetch.sh fluo
  else
    "$bin"/impl/fetch.sh "$1" "$2"
  fi
}

function uno_wipe_main() {
  local yn
  uno_kill_main
  read -r -p "Are you sure you want to wipe '$INSTALL'? [Y/n] " yn
  case "$yn" in
    [yY]|[yY][eE][sS])
      if [[ -d $INSTALL && $INSTALL != '/' ]]; then
        echo "removing $INSTALL"
        rm -rf "${INSTALL:?}"
      fi
      ;;
    *)
      exit
      ;;
  esac
}

function uno_help_main() {
  cat <<EOF
Usage: uno <command> (<argument>)

Possible commands:

  fetch   <component>    Fetches binary tarballs of component and it dependencies by either building or downloading
                         the tarball (as configured by uno.conf). Run 'uno fetch all' to fetch all binary tarballs.
  install <component>    Installs component and its dependencies (clearing any existing data)
  run     <component>    Runs component and its dependencies (clearing any existing data)
  setup   <component>    Installs and runs component and its dependencies (clearing any existing data)
  start   <component>    Start ZooKeeper, Hadoop, Accumulo, if not running.
  stop    <component>    Stop Accumulo, Hadoop, ZooKeeper, if running.
  status                 Check if Accumulo, Hadoop, or Zookeeper are running.
  kill                   Kills all processes
  ashell                 Runs the Accumulo shell
  zk                     Connects to ZooKeeper CLI
  env                    Prints out shell configuration for PATH and common environment variables.
                         Add '--paths' or '--vars' command to limit what is printed.
  version <dep>          Prints out configured version for dependency
  wipe                   Kills all processes and clears install directory

Possible components: accumulo, fluo, fluo-yarn, hadoop, zookeeper
EOF
}

# commands.sh
