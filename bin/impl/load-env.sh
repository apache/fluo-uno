#! /usr/bin/env bash

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

# Start: Resolve Script Directory
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do # resolve $SOURCE until the file is no longer a symlink
   impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
   SOURCE="$(readlink "$SOURCE")"
   [[ $SOURCE != /* ]] && SOURCE="$impl/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
bin="$( cd -P "$( dirname "$impl" )" && pwd )"
# Stop: Resolve Script Directory

# Determine FLUO_DEV - Use env variable set by user.  If none set, calculate using bin dir
FLUO_DEV="${FLUO_DEV:-$( cd -P "${bin}"/.. && pwd )}"
export FLUO_DEV
if [[ -z "$FLUO_DEV" || ! -d "$FLUO_DEV" ]]
then
  echo "FLUO_DEV=$FLUO_DEV is not a valid directory.  Please make sure it exists"
  exit 1
fi

HP=$HADOOP_PREFIX
HC=$HADOOP_CONF_DIR
ZH=$ZOOKEEPER_HOME
SH=$SPARK_HOME
AH=$ACCUMULO_HOME
FH=$FLUO_HOME

# Load env configuration
if [[ -f "$FLUO_DEV/conf/env.sh" ]]; then
  if [[ ! "version env" =~ $1 ]]; then echo "fluo-dev is using custom configuration at $FLUO_DEV/conf/env.sh"; fi
  . "$FLUO_DEV"/conf/env.sh
else
  if [[ ! "version env" =~ $1 ]]; then echo "fluo-dev is using default configuration at $FLUO_DEV/conf/env.sh.example"; fi
  . "$FLUO_DEV"/conf/env.sh.example
fi

# Confirm that hadoop, accumulo, and zookeeper env variables are not set
if [[ ! "version env" =~ $1 ]]; then
  if [[ -n "$HP" && "$HP" != "$HADOOP_PREFIX" ]]; then
    echo "HADOOP_PREFIX in your shell env '$HP' needs to match your fluo-dev env.sh '$HADOOP_PREFIX'"
    exit 1
  fi
  if [[ -n "$HC" && "$HC" != "$HADOOP_CONF_DIR" ]]; then
    echo "HADOOP_CONF_DIR in your shell env '$HC' needs to match your fluo-dev env.sh '$HADOOP_CONF_DIR'"
    exit 1
  fi
  if [[ -n "$ZH" && "$ZH" != "$ZOOKEEPER_HOME" ]]; then
    echo "ZOOKEEPER_HOME in your shell env '$ZH' needs to match your fluo-dev env.sh '$ZOOKEEPER_HOME'"
    exit 1
  fi
  if [[ -n "$SH" && "$SH" != "$SPARK_HOME" ]]; then
    echo "SPARK_HOME in your shell env '$SH' needs to match your fluo-dev env.sh '$SPARK_HOME'"
    exit 1
  fi
  if [[ -n "$AH" && "$AH" != "$ACCUMULO_HOME" ]]; then
    echo "ACCUMULO_HOME in your shell env '$AH' needs to match your fluo-dev env.sh '$ACCUMULO_HOME'"
    exit 1
  fi
  if [[ -n "$FH" && "$FH" != "$FLUO_HOME" ]]; then
    echo "FLUO_HOME in your shell env '$FH' needs to match your fluo-dev env.sh '$FLUO_HOME'"
    exit 1
  fi
fi

# Confirm that env variables were set correctly
if [[ -n "$FLUO_TARBALL_PATH" && ! -f "$FLUO_TARBALL_PATH" ]]; then
  echo "FLUO_TARBALL_PATH=$FLUO_TARBALL_PATH is not a valid file.  Please make sure it exists"
  exit 1
fi
if [[ -n "$FLUO_TARBALL_REPO" && ! -d "$FLUO_TARBALL_REPO" ]]; then
  echo "FLUO_TARBALL_REPO=$FLUO_TARBALL_REPO is not a valid directory.  Please make sure it exists"
  exit 1
fi

if [[ -z "$INSTALL" ]]; then
  echo "INSTALL=$INSTALL needs to be set in env.sh"
  exit 1
fi

if [[ ! -d "$INSTALL" ]]; then
  mkdir -p "$INSTALL"
fi

: "${DATA_DIR:?"DATA_DIR is not set in env.sh"}"
: "${FLUO_VERSION:?"FLUO_VERSION is not set in env.sh"}"
: "${HADOOP_VERSION:?"HADOOP_VERSION is not set in env.sh"}"
: "${ZOOKEEPER_VERSION:?"ZOOKEEPER_VERSION is not set in env.sh"}"
: "${ACCUMULO_VERSION:?"ACCUMULO_VERSION is not set in env.sh"}"
: "${DOWNLOADS:?"DOWNLOADS is not set in env.sh"}"
: "${ACCUMULO_TARBALL:?"ACCUMULO_TARBALL is not set in env.sh"}"
: "${FLUO_TARBALL:?"FLUO_TARBALL is not set in env.sh"}"
: "${HADOOP_TARBALL:?"HADOOP_TARBALL is not set in env.sh"}"
: "${ZOOKEEPER_TARBALL:?"ZOOKEEPER_TARBALL is not set in env.sh"}"
: "${FLUO_HOME:?"FLUO_HOME is not set in env.sh"}"
: "${ZOOKEEPER_HOME:?"ZOOKEEPER_HOME is not set in env.sh"}"
: "${HADOOP_PREFIX:?"HADOOP_PREFIX is not set in env.sh"}"
: "${ACCUMULO_HOME:?"ACCUMULO_HOME is not set in env.sh"}"
: "${ACCUMULO_INSTANCE:?"ACCUMULO_INSTANCE is not set in env.sh"}"
: "${ACCUMULO_USER:?"ACCUMULO_USER is not set in env.sh"}"
: "${ACCUMULO_PASSWORD:?"ACCUMULO_PASSWORD is not set in env.sh"}"
: "${START_SPARK_HIST_SERVER:?"START_SPARK_HIST_SERVER is not set in env.sh"}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  export MD5="md5 -q"
  export SED="sed -i .bak"
else
  export MD5=md5sum
  export SED="sed -i"
fi
