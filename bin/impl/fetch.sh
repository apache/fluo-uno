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

source "$UNO_HOME"/bin/impl/util.sh

function fetch_hadoop() {
  download_apache "hadoop/common/hadoop-$HADOOP_VERSION" "$HADOOP_TARBALL" "$HADOOP_HASH"
}

function fetch_zookeeper() {
  download_apache "zookeeper/zookeeper-$ZOOKEEPER_VERSION" "$ZOOKEEPER_TARBALL" "$ZOOKEEPER_HASH"
}

function fetch_accumulo() {
  if [[ $1 != "--no-deps" ]]; then
    fetch_hadoop
    fetch_zookeeper
  fi

  if [[ -n "$ACCUMULO_REPO" ]]; then
    declare -a maven_args=(-DskipTests -DskipFormat)
    if [[ "${HADOOP_VERSION}" = 3.* ]]; then
      maven_args=("${maven_args[@]}" '-Dhadoop.profile=3')
    fi
    rm -f "$DOWNLOADS/$ACCUMULO_TARBALL"
    pushd .
    cd "$ACCUMULO_REPO"
    mvn -V -e clean package "${maven_args[@]}"
    accumulo_built_tarball=$ACCUMULO_REPO/assemble/target/$ACCUMULO_TARBALL
    if [[ ! -f "$accumulo_built_tarball" ]]; then
      echo
      echo "The following file does not exist :"
      echo "    $accumulo_built_tarball"
      echo "after building from :"
      echo "    ACCUMULO_REPO=$ACCUMULO_REPO"
      echo "ensure ACCUMULO_VERSION=$ACCUMULO_VERSION is correct."
      echo
      exit 1
    fi
    popd
    cp "$accumulo_built_tarball" "$DOWNLOADS"/
  else
    download_apache "accumulo/$ACCUMULO_VERSION" "$ACCUMULO_TARBALL" "$ACCUMULO_HASH"
  fi
}

function fetch_fluo() {
  if [[ $1 != "--no-deps" ]]; then
    fetch_accumulo
  fi
  if [[ -n "$FLUO_REPO" ]]; then
    rm -f "$DOWNLOADS/$FLUO_TARBALL"
    cd "$FLUO_REPO"
    mvn -V -e clean package -DskipTests -Dformatter.skip

    fluo_built_tarball=$FLUO_REPO/modules/distribution/target/$FLUO_TARBALL
    if [[ ! -f "$fluo_built_tarball" ]]; then
      echo "The tarball $fluo_built_tarball does not exist after building from the FLUO_REPO=$FLUO_REPO"
      echo "Does your repo contain code matching the FLUO_VERSION=$FLUO_VERSION set in uno.conf?"
      exit 1
    fi
    cp "$fluo_built_tarball" "$DOWNLOADS"/
  else
    [[ $FLUO_VERSION =~ .*-incubating ]] && apache_mirror="${apache_mirror}/incubator"
    download_apache "fluo/fluo/$FLUO_VERSION" "$FLUO_TARBALL" "$FLUO_HASH"
  fi
}

# Determine best apache mirror to use
apache_mirror=$(curl -sk https://apache.org/mirrors.cgi?as_json | grep preferred | cut -d \" -f 4)

if [ -z "$apache_mirror" ]; then
  echo "Failed querying apache.org for best download mirror!"
  echo "Fetch can only verify existing downloads or build Accumulo/Fluo tarballs from a repo."
fi

case "$1" in
accumulo)
  fetch_accumulo "$2"
  ;;
fluo)
  fetch_fluo "$2"
  ;;
fluo-yarn)
  if [[ $2 != "--no-deps" ]]; then
    fetch_fluo
  fi
  if [[ -n "$FLUO_YARN_REPO" ]]; then
    rm -f "$DOWNLOADS/$FLUO_YARN_TARBALL"
    cd "$FLUO_YARN_REPO"
    mvn -V -e clean package -DskipTests -Dformatter.skip

    built_tarball=$FLUO_YARN_REPO/target/$FLUO_YARN_TARBALL
    if [[ ! -f "$built_tarball" ]]; then
      echo "The tarball $built_tarball does not exist after building from the FLUO_YARN_REPO=$FLUO_YARN_REPO"
      echo "Does your repo contain code matching the FLUO_YARN_VERSION=$FLUO_YARN_VERSION set in uno.conf?"
      exit 1
    fi
    cp "$built_tarball" "$DOWNLOADS"/
  else
    download_apache "fluo/fluo-yarn/$FLUO_YARN_VERSION" "$FLUO_YARN_TARBALL" "$FLUO_YARN_HASH"
  fi
  ;;
hadoop)
  fetch_hadoop
  ;;
zookeeper)
  fetch_zookeeper
  ;;
*)
  echo "Usage: uno fetch <component>"
  echo -e "\nPossible components:\n"
  echo "    accumulo   Downloads Accumulo, Hadoop & ZooKeeper. Builds Accumulo if repo set in uno.conf"
  echo "    fluo       Downloads Fluo, Accumulo, Hadoop & ZooKeeper. Builds Fluo or Accumulo if repo set in uno.conf"
  echo "    hadoop     Downloads Hadoop"
  echo "    zookeeper  Downloads ZooKeeper"
  echo "Options:"
  echo "    --no-deps  Dependencies will be fetched unless this option is specified. Only works for fluo & accumulo components."
  exit 1
esac
