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

# stop if any command fails
set -e

function verify_exist_hash() {
  tarball=$1
  expected_md5=$2
  actual_md5=$($MD5 "$DOWNLOADS/$tarball" | awk '{print $1}')

  if [[ ! -f "$DOWNLOADS/$tarball" ]]; then
    echo "The tarball $tarball does not exists in downloads/"
    exit 1
  fi
  if [[ "$actual_md5" != "$expected_md5" ]]; then
    echo "The MD5 checksum ($actual_md5) of $tarball does not match the expected checksum ($expected_md5)"
    exit 1
  fi
}

if [[ -n "$FLUO_TARBALL_PATH" ]]; then
  TARBALL=$FLUO_TARBALL_PATH
elif [[ -n "$FLUO_TARBALL_REPO" ]]; then
  echo "Rebuilding Fluo tarball" 
  cd "$FLUO_TARBALL_REPO"
  mvn clean package -DskipTests -Daccumulo.version="$ACCUMULO_VERSION" -Dhadoop.version="$HADOOP_VERSION" -Dthrift.version="$THRIFT_VERSION"
  # mvn command above puts shell in weird state where commands are not echoed when typed.  command below fixes this.
  stty echo

  TARBALL=$FLUO_TARBALL_REPO/modules/distribution/target/fluo-$FLUO_VERSION-bin.tar.gz
  if [[ ! -f "$TARBALL" ]]; then
    echo "The tarball $TARBALL does not exist after building from the FLUO_TARBALL_REPO=$FLUO_TARBALL_REPO"
    echo "Does your repo contain code matching the FLUO_VERSION=$FLUO_VERSION set in env.sh?"
    exit 1
  fi
elif [[ -n "$FLUO_TARBALL_URL_PREFIX" ]]; then
  verify_exist_hash "$FLUO_TARBALL" "$FLUO_MD5"
  TARBALL=$DOWNLOADS/$FLUO_TARBALL
else
  echo "Fluo tarball location was not set in conf/env.sh.  Fluo will not be set up."
fi

if [[ -n "$TARBALL" ]]; then
  echo "Killing Fluo (if running)"
  # Don't stop if pkills fail
  set +e
  pkill -f fluo.yarn
  pkill -f MiniFluo
  pkill -f twill.launcher
  set -e

  echo "Removing old Fluo deployment" 
  rm -rf "$FLUO_HOME"

  echo "Deploying new Fluo tarball"
  tar xzf "$TARBALL" -C "$INSTALL"/

  echo "Configuring Fluo"
  # Copy example config to deployment
  cp "$FLUO_HOME"/conf/examples/* "$FLUO_HOME"/conf/
  FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
  $SED "s/org.apache.fluo.client.accumulo.instance=/org.apache.fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" "$FLUO_PROPS"
  $SED "s/org.apache.fluo.client.accumulo.user=/org.apache.fluo.client.accumulo.user=$ACCUMULO_USER/g" "$FLUO_PROPS"
  $SED "s/org.apache.fluo.client.accumulo.password=/org.apache.fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" "$FLUO_PROPS"
  $SED "s/.*org.apache.fluo.worker.num.threads=.*/org.apache.fluo.worker.num.threads=$FLUO_WORKER_THREADS/g" "$FLUO_PROPS"
  $SED "s/.*org.apache.fluo.worker.max.memory.mb=.*/org.apache.fluo.worker.max.memory.mb=$FLUO_WORKER_MEM_MB/g" "$FLUO_PROPS"
  $SED "s/.*org.apache.fluo.worker.instances=.*/org.apache.fluo.worker.instances=$FLUO_WORKER_INSTANCES/g" "$FLUO_PROPS"
  $SED "s#HADOOP_PREFIX=/path/to/hadoop#HADOOP_PREFIX=$HADOOP_PREFIX#g" "$FLUO_HOME"/conf/fluo-env.sh
  
  if [[ "$SETUP_METRICS" == "true" ]]; then
    $SED "/org.apache.fluo.metrics.reporter.graphite/d" "$FLUO_PROPS"
    {
      echo "org.apache.fluo.metrics.reporter.graphite.enable=true"
      echo "org.apache.fluo.metrics.reporter.graphite.host=localhost"
      echo "org.apache.fluo.metrics.reporter.graphite.port=2003"
      echo "org.apache.fluo.metrics.reporter.graphite.frequency=30"
    } >> "$FLUO_PROPS"
  fi
fi
