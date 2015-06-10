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

# Load env configuration
if [ -f "$FLUO_DEV/conf/env.sh" ]; then
  echo "fluo-dev is using custom configuration at $FLUO_DEV/conf/env.sh"
  . $FLUO_DEV/conf/env.sh
else
  echo "fluo-dev is using default configuration at $FLUO_DEV/conf/env.sh.example"
  . $FLUO_DEV/conf/env.sh.example
fi

# Confirm that env variables were set correctly
if [ -z "$FLUO_TARBALL_PATH" -a -z "$FLUO_TARBALL_REPO" -a -z "$FLUO_TARBALL_URL" ]; then
  echo "You must set one of FLUO_TARBALL_PATH, FLUO_TARBALL_REPO or FLUO_TARBALL_URL!"
  exit 1
fi
if [ -n "$FLUO_TARBALL_PATH" -a ! -f "$FLUO_TARBALL_PATH" ]; then
  echo "FLUO_TARBALL_PATH=$FLUO_TARBALL_PATH is not a valid file.  Please make sure it exists"
  exit 1
fi
if [ -n "$FLUO_TARBALL_REPO" -a ! -d "$FLUO_TARBALL_REPO" ]; then
  echo "FLUO_TARBALL_REPO=$FLUO_TARBALL_REPO is not a valid directory.  Please make sure it exists"
  exit 1
fi

if [ -z "$INSTALL" ]; then
  echo "INSTALL=$INSTALL needs to be set in env.sh"
  exit 1
fi

if [ ! -d $INSTALL ]; then
  mkdir -p $INSTALL
fi

: ${DATA_DIR:?"DATA_DIR is not set in env.sh"}
: ${FLUO_VERSION:?"FLUO_VERSION is not set in env.sh"}
: ${HADOOP_VERSION:?"HADOOP_VERSION is not set in env.sh"}
: ${ZOOKEEPER_VERSION:?"ZOOKEEPER_VERSION is not set in env.sh"}
: ${ACCUMULO_VERSION:?"ACCUMULO_VERSION is not set in env.sh"}
: ${DOWNLOADS:?"DOWNLOADS is not set in env.sh"}
: ${APACHE_MIRROR:?"APACHE_MIRROR is not set in env.sh"}
: ${ACCUMULO_TARBALL:?"ACCUMULO_TARBALL is not set in env.sh"}
: ${HADOOP_TARBALL:?"HADOOP_TARBALL is not set in env.sh"}
: ${ZOOKEEPER_TARBALL:?"ZOOKEEPER_TARBALL is not set in env.sh"}
: ${FLUO_HOME:?"FLUO_HOME is not set in env.sh"}
: ${ZOOKEEPER_HOME:?"ZOOKEEPER_HOME is not set in env.sh"}
: ${HADOOP_PREFIX:?"HADOOP_PREFIX is not set in env.sh"}
: ${ACCUMULO_HOME:?"ACCUMULO_HOME is not set in env.sh"}
: ${ACCUMULO_INSTANCE:?"ACCUMULO_INSTANCE is not set in env.sh"}
: ${ACCUMULO_USER:?"ACCUMULO_USER is not set in env.sh"}
: ${ACCUMULO_PASSWORD:?"ACCUMULO_PASSWORD is not set in env.sh"}

if [[ "$OSTYPE" == "darwin"* ]]; then
  export MD5=md5
  export SED="sed -i .bak"
else
  export MD5=md5sum
  export SED="sed -i"
fi
