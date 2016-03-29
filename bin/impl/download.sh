#!/bin/bash

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

function download_verify() {
  url_prefix=$1
  tarball=$2
  expected_md5=$3

  exp_md5_len=${#expected_md5}
  if [ $exp_md5_len != 32 ]; then
    echo "The expected MD5 checksum ($expected_md5) of $tarball has a length of $exp_md5_len but should be 32"
    exit 1
  fi
  
  wget -c -P $DOWNLOADS $url_prefix/$tarball
  actual_md5=`$MD5 $DOWNLOADS/$tarball | awk '{print $1}'`

  if [[ "$actual_md5" != "$expected_md5" ]]; then
    echo "The MD5 checksum ($actual_md5) of $tarball does not match the expected checksum ($expected_md5)"
    exit 1
  fi
  echo "$tarball exists in downloads/ and matches expected MD5 ($expected_md5)"
}

download_verify $APACHE_MIRROR/hadoop/common/hadoop-$HADOOP_VERSION $HADOOP_TARBALL $HADOOP_MD5
download_verify $APACHE_MIRROR/zookeeper/zookeeper-$ZOOKEEPER_VERSION $ZOOKEEPER_TARBALL $ZOOKEEPER_MD5
download_verify $APACHE_MIRROR/spark/spark-$SPARK_VERSION $SPARK_TARBALL $SPARK_MD5

if [ -n "$ACCUMULO_TARBALL_REPO" ]; then
  rm -f $DOWNLOADS/$ACCUMULO_TARBALL
  pushd .
  cd $ACCUMULO_TARBALL_REPO
  mvn clean package -Passemble -DskipTests
  ACCUMULO_BUILT_TAR=$ACCUMULO_TARBALL_REPO/assemble/target/accumulo-$ACCUMULO_VERSION-bin.tar.gz
  if [ ! -f $ACCUMULO_BUILT_TAR ]; then
    echo
    echo "The following file does not exist :"
    echo "    $ACCUMULO_BUILT_TAR"
    echo "after building from :"
    echo "    ACCUMULO_TARBALL_REPO=$ACCUMULO_TARBALL_REPO"
    echo "ensure ACCUMULO_VERSION=$ACCUMULO_VERSION is correct."
    echo
    exit 1
  fi
  popd
  cp $ACCUMULO_BUILT_TAR $DOWNLOADS/
else
  download_verify $APACHE_MIRROR/accumulo/$ACCUMULO_VERSION $ACCUMULO_TARBALL $ACCUMULO_MD5
fi

if [ -z "$FLUO_TARBALL_PATH" -a -z "$FLUO_TARBALL_REPO" -a -n "$FLUO_TARBALL_URL_PREFIX" ]; then
  download_verify $FLUO_TARBALL_URL_PREFIX $FLUO_TARBALL $FLUO_MD5
fi

if [ $SETUP_METRICS = "true" ]; then

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "The metrics services (InfluxDB and Grafana) are not supported on Mac OS X at this time."
    echo "You should set SETUP_METRICS to false in env.sh."
    exit 1
  fi

  BUILD=$DOWNLOADS/build
  rm -rf $BUILD
  mkdir -p $BUILD
  IF_DIR=influxdb-$INFLUXDB_VERSION
  IF_PATH=$BUILD/$IF_DIR
  GF_DIR=grafana-$GRAFANA_VERSION
  GF_PATH=$BUILD/$GF_DIR

  INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
  download_verify https://s3.amazonaws.com/influxdb $INFLUXDB_TARBALL $INFLUXDB_MD5

  tar xzf $DOWNLOADS/$INFLUXDB_TARBALL -C $BUILD
  mv $BUILD/influxdb_"$INFLUXDB_VERSION"_x86_64 $IF_PATH
  mkdir $IF_PATH/bin
  mv $IF_PATH/opt/influxdb/versions/$INFLUXDB_VERSION/* $IF_PATH/bin
  rm -rf $IF_PATH/opt

  cd $BUILD
  tar czf influxdb-"$INFLUXDB_VERSION".tar.gz $IF_DIR
  rm -rf $IF_PATH

  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
  download_verify https://grafanarel.s3.amazonaws.com/builds $GRAFANA_TARBALL $GRAFANA_MD5

  tar xzf $DOWNLOADS/$GRAFANA_TARBALL -C $BUILD

  cd $BUILD
  tar czf grafana-"$GRAFANA_VERSION".tar.gz $GF_DIR
  rm -rf $GF_PATH
fi

echo "Success! All tarballs have been downloaded and their checksums verified."
