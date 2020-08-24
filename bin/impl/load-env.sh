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

# Determine UNO_HOME - Use env variable set by user. If none set, calculate using bin dir
UNO_HOME="${UNO_HOME:-$( cd -P "${bin}"/.. && pwd )}"
export UNO_HOME
if [[ -z $UNO_HOME || ! -d $UNO_HOME ]]; then
  echo "UNO_HOME=$UNO_HOME is not a valid directory. Please make sure it exists"
  exit 1
fi

HH=$HADOOP_HOME
HC=$HADOOP_CONF_DIR
ZH=$ZOOKEEPER_HOME
SH=$SPARK_HOME
AH=$ACCUMULO_HOME
FH=$FLUO_HOME

# Load env configuration
if [[ -f "$UNO_HOME/conf/uno-local.conf" ]]; then
  # shellcheck source=conf/uno.conf
  source "$UNO_HOME"/conf/uno-local.conf
elif [[ -f "$UNO_HOME/conf/uno.conf" ]]; then
  # shellcheck source=conf/uno.conf
  source "$UNO_HOME"/conf/uno.conf
else
  echo "ERROR: Configuration file $UNO_HOME/conf/uno.conf does not exist" 1>&2
  exit 1
fi

function env_error() {
  echo "$1 in your shell env '$2' needs to match your uno.conf '$3'"
  echo 'Make your shell env match uno.conf by running: source <(./bin/uno env)'
  exit 1
}

# Confirm that hadoop, accumulo, and zookeeper env variables are not set
if [[ ! "version env" =~ $1 ]]; then
  [[ -n "$HH" && "$HH" != "$HADOOP_HOME" ]] && env_error 'HADOOP_HOME' "$HH" "$HADOOP_HOME"
  [[ -n "$HC" && "$HC" != "$HADOOP_CONF_DIR" ]] && env_error 'HADOOP_CONF_DIR' "$HC" "$HADOOP_CONF_DIR"
  [[ -n "$ZH" && "$ZH" != "$ZOOKEEPER_HOME" ]] && env_error 'ZOOKEEPER_HOME' "$ZH" "$ZOOKEEPER_HOME"
  [[ -n "$SH" && "$SH" != "$SPARK_HOME" ]] && env_error 'SPARK_HOME' "$SH" "$SPARK_HOME"
  [[ -n "$AH" && "$AH" != "$ACCUMULO_HOME" ]] && env_error 'ACCUMULO_HOME' "$AH" "$ACCUMULO_HOME"
  [[ -n "$FH" && "$FH" != "$FLUO_HOME" ]] && env_error 'FLUO_HOME' "$FH" "$FLUO_HOME"
fi

# Confirm that env variables were set correctly
if [[ -n "$FLUO_REPO" && ! -d "$FLUO_REPO" ]]; then
  echo "FLUO_REPO=$FLUO_REPO is not a valid directory. Please make sure it exists"
  exit 1
fi
if [[ -n "$ACCUMULO_REPO" && ! -d "$ACCUMULO_REPO" ]]; then
  echo "ACCUMULO_REPO=$ACCUMULO_REPO is not a valid directory. Please make sure it exists"
  exit 1
fi

if [[ -z "$INSTALL" ]]; then
  echo "INSTALL=$INSTALL needs to be set in uno.conf"
  exit 1
fi

if [[ ! -d "$INSTALL" ]]; then
  mkdir -p "$INSTALL"
fi

if [[ -z "$JAVA_HOME" || ! -d "$JAVA_HOME" ]]; then
  echo "JAVA_HOME must be set in your shell to a valid directory. Currently, JAVA_HOME=$JAVA_HOME"
  exit 1
fi

: "${DATA_DIR:?"DATA_DIR is not set in uno.conf"}"
: "${FLUO_VERSION:?"FLUO_VERSION is not set in uno.conf"}"
: "${HADOOP_VERSION:?"HADOOP_VERSION is not set in uno.conf"}"
: "${ZOOKEEPER_VERSION:?"ZOOKEEPER_VERSION is not set in uno.conf"}"
: "${ACCUMULO_VERSION:?"ACCUMULO_VERSION is not set in uno.conf"}"
: "${DOWNLOADS:?"DOWNLOADS is not set in uno.conf"}"
: "${ACCUMULO_TARBALL:?"ACCUMULO_TARBALL is not set in uno.conf"}"
: "${FLUO_TARBALL:?"FLUO_TARBALL is not set in uno.conf"}"
: "${HADOOP_TARBALL:?"HADOOP_TARBALL is not set in uno.conf"}"
: "${ZOOKEEPER_TARBALL:?"ZOOKEEPER_TARBALL is not set in uno.conf"}"
: "${FLUO_HOME:?"FLUO_HOME is not set in uno.conf"}"
: "${ZOOKEEPER_HOME:?"ZOOKEEPER_HOME is not set in uno.conf"}"
: "${HADOOP_HOME:?"HADOOP_HOME is not set in uno.conf"}"
: "${ACCUMULO_HOME:?"ACCUMULO_HOME is not set in uno.conf"}"
: "${ACCUMULO_INSTANCE:?"ACCUMULO_INSTANCE is not set in uno.conf"}"
: "${ACCUMULO_USER:?"ACCUMULO_USER is not set in uno.conf"}"
: "${ACCUMULO_PASSWORD:?"ACCUMULO_PASSWORD is not set in uno.conf"}"
: "${LOGS_DIR:?"LOGS_DIR is not set in uno.conf"}"
: "${ACCUMULO_LOG_DIR:?"ACCUMULO_LOG_DIR is not set in uno.conf"}"
: "${HADOOP_LOG_DIR:?"HADOOP_LOG_DIR is not set in uno.conf"}"
: "${ZOO_LOG_DIR:?"ZOO_LOG_DIR is not set in uno.conf"}"

if [[ -z $HADOOP_HASH ]]; then
  echo "HADOOP_HASH is not set. Set it for your version in 'conf/checksums' or uno.conf"
  exit 1
fi
if [[ -z $ZOOKEEPER_HASH ]]; then
  echo "ZOOKEEPER_HASH is not set. Set it for your version in 'conf/checksums' or uno.conf"
  exit 1
fi
if [[ -z $ACCUMULO_HASH && ! $ACCUMULO_VERSION =~ SNAPSHOT ]]; then
  echo "ACCUMULO_HASH is not set. Set it for your version in 'conf/checksums' or uno.conf"
  exit 1
fi

hash shasum 2>/dev/null || { echo >&2 "shasum must be installed & on PATH. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "sed must be installed & on PATH. Aborting."; exit 1; }

if [[ $OSTYPE =~ ^darwin ]]; then
  export SED="sed -i .bak"
else
  export SED="sed -i"
fi

# load-env.sh
