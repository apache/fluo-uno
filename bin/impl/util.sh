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

# check if running in a color terminal
function terminalSupportsColor() { local c; c=$(tput colors 2>/dev/null) || c=-1; [[ -t 1 ]] && [[ $c -ge 8 ]]; }
terminalSupportsColor && doColor=1 || doColor=0
function color() { local c; c=$1; shift; [[ $doColor -eq 1 ]] && echo -e "\\e[0;${c}m${*}\\e[0m" || echo "$@"; }
function red() { color 31 "$@"; }
function green() { color 32 "$@"; }
function yellow() { color 33 "$@"; }

function verify_exist_hash() {
  local tarball=$1 expected_hash actual_hash hash_cmd
  expected_hash=$(echo "${2// /}" | tr '[:upper:]' '[:lower:]')

  if [[ ! -f $DOWNLOADS/$tarball ]]; then
    print_to_console "The tarball $tarball does not exist in downloads/"
    return 1
  fi

  case "${#expected_hash}" in
    32) hash_cmd='md5sum' ;;
    40) hash_cmd='shasum -a 1' ;;
    64) hash_cmd='shasum -a 256' ;;
    128) hash_cmd='shasum -a 512' ;;
    *)
      print_to_console "Expected checksum ($(red "$expected_hash")) of $(yellow "$tarball") is not an MD5, SHA1, SHA256, or SHA512 sum"
      return 1
      ;;
  esac
  actual_hash=$($hash_cmd "$DOWNLOADS/$tarball" | awk '{print $1}')

  if [[ $actual_hash != "$expected_hash" ]]; then
    print_to_console "The actual checksum ($(red "$actual_hash")) of $(yellow "$tarball") does not match the expected checksum ($(green "$expected_hash"))"
    return 1
  fi
}

# Takes directory variables as arguments
function check_dirs() {
  for arg in "$@"; do
    if [[ ! -d ${!arg} ]]; then
      print_to_console "$arg=${!arg} is not a valid directory. Please make sure it exists"
      return 1
    fi
  done
}

function post_install_plugins() {
  for plugin in $POST_INSTALL_PLUGINS; do
    echo "Executing post install plugin: $plugin"
    plugin_script="${UNO_HOME}/plugins/${plugin}.sh"
    if [[ ! -f $plugin_script ]]; then
      echo "Plugin does not exist: $plugin_script"
      return 1
    fi
    "$plugin_script" || return 1
  done
}

function post_run_plugins() {
  for plugin in $POST_RUN_PLUGINS; do
    echo "Executing post run plugin: $plugin"
    plugin_script="${UNO_HOME}/plugins/${plugin}.sh"
    if [[ ! -f "$plugin_script" ]]; then
      echo "Plugin does not exist: $plugin_script"
      return 1
    fi
    "$plugin_script" || return 1
  done
}

function install_component() {
  local component; component=$(echo "$1" | tr '[:upper:] ' '[:lower:]-')
  shift
  "$UNO_HOME/bin/impl/install/$component.sh" "$@" || return 1
  case "$component" in
    accumulo|fluo) post_install_plugins ;;
    *) ;;
  esac
}

function run_component() {
  local component; component=$(echo "$1" | tr '[:upper:] ' '[:lower:]-')
  local logs; logs="$LOGS_DIR/setup"
  mkdir -p "$logs"
  shift
  "$UNO_HOME/bin/impl/run/$component.sh" "$@" 1>"$logs/${component}.out" 2>"$logs/${component}.err" || return 1
  case "$component" in
    accumulo|fluo) post_run_plugins ;;
    *) ;;
  esac
}

function setup_component() {
  install_component "$@" && run_component "$@"
}

function save_console_fd {
  if [[ -z $UNO_CONSOLE_FD && ! $OSTYPE =~ ^darwin ]]; then
    # Allocate an unused file descriptor and make it dup stdout
    # https://stackoverflow.com/a/41620630/7298689
    exec {UNO_CONSOLE_FD}>&1
    export UNO_CONSOLE_FD
  fi
}

function print_to_console {
  if [[ -z $UNO_CONSOLE_FD ]]; then
    echo "$@"
  else
    echo "$@" >&${UNO_CONSOLE_FD}
  fi
}

function download_tarball() {
  local url_prefix=$1 tarball=$2 expected_hash=$3
  verify_exist_hash "$tarball" "$expected_hash" &>/dev/null || \
  wget -c -P "$DOWNLOADS" "$url_prefix/$tarball"
  verify_exist_hash "$tarball" "$expected_hash" || return 1
  echo "$(yellow "$tarball") download matches expected checksum ($(green "$expected_hash"))"
}

function download_apache() {
  local url_prefix=$1 tarball=$2 expected_hash=$3
  verify_exist_hash "$tarball" "$expected_hash" &>/dev/null || \
  {
    [[ -n "${apache_mirror:-}" ]] && wget -c -P "$DOWNLOADS" "$apache_mirror/$url_prefix/$tarball"
    if [[ ! -f "$DOWNLOADS/$tarball" ]]; then
      echo "Downloading $tarball from Apache archive"
      wget -c -P "$DOWNLOADS" "https://archive.apache.org/dist/$url_prefix/$tarball"
    fi
  }
  verify_exist_hash "$tarball" "$expected_hash" || return 1
  echo "$(yellow "$tarball") download matches expected checksum ($(green "$expected_hash"))"
}

function print_cmd_usage() {
    cat <<EOF
Usage: uno $1 <component> [--no-deps] [--test]

Possible components:

    accumulo   $2 Apache Accumulo and its dependencies (Hadoop & ZooKeeper)
    hadoop     $2 Apache Hadoop
    fluo       $2 Apache Fluo and its dependencies (Accumulo, Hadoop, & ZooKeeper)
    fluo-yarn  $2 Apache Fluo YARN and its dependencies (Fluo, Accumulo, Hadoop, & ZooKeeper)
    zookeeper  $2 Apache ZooKeeper

Options (these only work for fluo and accumulo components):
    --no-deps  Dependencies will be setup unless this option is specified.
    --test     Copy the test jar built in accumulo to downloads. Requires ACCUMULO_REPO
EOF
}

# util.sh
