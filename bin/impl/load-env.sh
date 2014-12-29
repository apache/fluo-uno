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
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
   impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
   SOURCE="$(readlink "$SOURCE")"
   [[ $SOURCE != /* ]] && SOURCE="$impl/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
bin="$( cd -P "$( dirname "$impl" )" && pwd )"
script=$( basename "$SOURCE" )
# Stop: Resolve Script Directory

# Determine FLUO_DEV - Use env variable set by user.  If none set, calculate using bin dir
FLUO_DEV="${FLUO_DEV:-$( cd -P ${bin}/.. && pwd )}"
export FLUO_DEV
if [ -z "$FLUO_DEV" -o ! -d "$FLUO_DEV" ]
then
  echo "FLUO_DEV=$FLUO_DEV is not a valid directory.  Please make sure it exists"
  exit 1
fi

# Confirm that hadoop, accumulo, and zookeeper env variables are not set
if [ -n "$HADOOP_PREFIX" ]; then
  echo "HADOOP_PREFIX should only be set in env.sh and not in your ~/.bashrc"
  exit 1
fi
if [ -n "$ZOOKEEPER_HOME" ]; then
  echo "ZOOKEEPER_HOME should only be set in env.sh and not in your ~/.bashrc"
  exit 1
fi
if [ -n "$ACCUMULO_HOME" ]; then
  echo "ACCUMULO_HOME should only be set in env.sh and not in your ~/.bashrc"
  exit 1
fi
if [ -n "$FLUO_HOME" ]; then
  echo "FLUO_HOME should only be set in env.sh and not in your ~/.bashrc"
  exit 1
fi

# Load env.sh if it exists
if [ ! -f "$FLUO_DEV/conf/env.sh" ]; then
  echo "The fluo-dev env.sh needs to be created at $FLUO_DEV/conf/env.sh"
  exit 1
fi
. $FLUO_DEV/conf/env.sh

# Confirm that env variables were set correctly
if [ -z "$HADOOP_PREFIX" -o ! -d "$HADOOP_PREFIX" ]; then
  echo "HADOOP_PREFIX=$HADOOP_PREFIX is not a valid directory.  Please make sure it exists and is set in env.sh"
  exit 1
fi
if [ -z "$ZOOKEEPER_HOME" -o ! -d "$ZOOKEEPER_HOME" ]; then
  echo "ZOOKEEPER_HOME=$ZOOKEEPER_HOME is not a valid directory.  Please make sure it exists and is set in env.sh"
  exit 1
fi
if [ -z "$ACCUMULO_HOME" -o ! -d "$ACCUMULO_HOME" ]; then
  echo "ACCUMULO_HOME=$ACCUMULO_HOME is not a valid directory.  Please make sure it exists and is set in env.sh"
  exit 1
fi
if [ -z "$FLUO_HOME" ]; then
  echo "FLUO_HOME is not set env.sh"
  exit 1
fi
if [ -z "$ACCUMULO_INSTANCE" ]; then
  echo "ACCUMULO_INSTANCE is not set env.sh"
  exit 1
fi
if [ -z "$ACCUMULO_USER" ]; then
  echo "ACCUMULO_USER is not set env.sh"
  exit 1
fi
if [ -z "$ACCUMULO_PASSWORD" ]; then
  echo "ACCUMULO_PASSWORD is not set env.sh"
  exit 1
fi
if [ -z "$ACCUMULO_TABLE" ]; then
  echo "ACCUMULO_TABLE is not set env.sh"
  exit 1
fi
