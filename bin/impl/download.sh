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

rm -f $DOWNLOADS/*.asc
rm -f $DOWNLOADS/*.md5

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
  ACCUMULO_PATH=accumulo/$ACCUMULO_VERSION
  wget -c -P $DOWNLOADS $APACHE_MIRROR/$ACCUMULO_PATH/$ACCUMULO_TARBALL
fi

if [ $SETUP_METRICS = "true" ]; then

  if [[ "$OSTYPE" == "darwin"* ]]; then
    BUILD_INFLUXDB=true
    BUILD_GRAFANA=true
  fi

  BUILD=$DOWNLOADS/build
  GOPATH=$BUILD/go
  rm -rf $BUILD
  mkdir -p $BUILD
  mkdir -p $GOPATH
  IF_DIR=influxdb-$INFLUXDB_VERSION
  IF_PATH=$BUILD/$IF_DIR
  GF_DIR=grafana-$GRAFANA_VERSION
  GF_PATH=$BUILD/$GF_DIR

  echo "Downloading InfluxDB tarball"
  INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
  wget -c -P $DOWNLOADS https://s3.amazonaws.com/influxdb/$INFLUXDB_TARBALL
  tar xzf $DOWNLOADS/$INFLUXDB_TARBALL -C $BUILD
  mv $BUILD/influxdb_"$INFLUXDB_VERSION"_x86_64 $IF_PATH
  mkdir $IF_PATH/bin
  mv $IF_PATH/opt/influxdb/versions/$INFLUXDB_VERSION/* $IF_PATH/bin
  rm -rf $IF_PATH/opt

  if [[ "$BUILD_INFLUXDB" == "true" ]]; then
    echo "Downloading InfluxDB source"
    hash go 2>/dev/null || { echo >&2 "Go lang must be installed & go command must be on path to build.  Aborting."; exit 1; }
    go get github.com/influxdb/influxdb
    echo "Building InfluxDB"
    cd $GOPATH/src/github.com/influxdb
    go get -u -f -t ./...
    cd $GOPATH/src/github.com/influxdb/influxdb
    git checkout tags/v"$INFLUXDB_VERSION"
    cd $GOPATH/src/github.com/influxdb
    go build ./...
    go install ./...
    echo "Replacing influx & influxd executables"
    cp $GOPATH/bin/influx $IF_PATH/bin
    cp $GOPATH/bin/influxd $IF_PATH/bin
  fi

  cd $BUILD
  tar czf influxdb-"$INFLUXDB_VERSION".tar.gz $IF_DIR
  rm -rf $IF_PATH

  echo "Downloading Grafana tarball"
  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
  wget -c -P $DOWNLOADS https://grafanarel.s3.amazonaws.com/builds/$GRAFANA_TARBALL
  tar xzf $DOWNLOADS/$GRAFANA_TARBALL -C $BUILD

  if [[ "$BUILD_GRAFANA" == "true" ]]; then
    echo "Downloading Grafana source"
    hash go 2>/dev/null || { echo >&2 "Go lang must be installed & go command must be on path to build.  Aborting."; exit 1; }
    go get github.com/grafana/grafana
    echo "Building Grafana"
    cd $GOPATH/src/github.com/grafana/grafana
    git checkout tags/v"$GRAFANA_VERSION"
    go run build.go setup
    $GOPATH/bin/godep restore
    go run build.go build
    echo "Replacing grafana-server executable"
    cp $GOPATH/src/github.com/grafana/grafana/bin/grafana-server $GF_PATH/bin
  fi

  cd $BUILD
  tar czf grafana-"$GRAFANA_VERSION".tar.gz $GF_DIR
  rm -rf $GF_PATH
fi

HADOOP_PATH=hadoop/common/hadoop-$HADOOP_VERSION
wget -c -P $DOWNLOADS $APACHE_MIRROR/$HADOOP_PATH/$HADOOP_TARBALL

ZOOKEEPER_PATH=zookeeper/zookeeper-$ZOOKEEPER_VERSION
wget -c -P $DOWNLOADS $APACHE_MIRROR/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL

SPARK_PATH=spark/spark-$SPARK_VERSION
wget -c -P $DOWNLOADS $APACHE_MIRROR/$SPARK_PATH/$SPARK_TARBALL

APACHE=https://www.apache.org/dist

echo -e "\nDownloading files hashes from Apache:"
if [ -z "$ACCUMULO_TARBALL_REPO" ]; then
  wget -nv -O $DOWNLOADS/$ACCUMULO_TARBALL.md5 $APACHE/$ACCUMULO_PATH/MD5SUM
fi

wget -nv -P $DOWNLOADS $APACHE/$HADOOP_PATH/$HADOOP_TARBALL.md5
wget -nv -P $DOWNLOADS $APACHE/$HADOOP_PATH/$HADOOP_TARBALL.mds
wget -nv -P $DOWNLOADS $APACHE/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL.md5
wget -nv -P $DOWNLOADS $APACHE/$SPARK_PATH/$SPARK_TARBALL.md5

echo -e "\nPlease confirm that the file hashes below match:"
echo -e "\nActual hashes generated from files using '$MD5':\n"
$MD5 $DOWNLOADS/*gz
echo -e "\nExpected hashes from Apache:\n"
cat $DOWNLOADS/*.md5
cat $DOWNLOADS/*.mds

if hash gpg 2>/dev/null; then
  echo -e "\nDownloading signatures from Apache:"
  if [ -z "$ACCUMULO_TARBALL_REPO" ]; then
    wget -nv -P $DOWNLOADS $APACHE/$ACCUMULO_PATH/$ACCUMULO_TARBALL.asc
  fi
  wget -nv -P $DOWNLOADS $APACHE/$HADOOP_PATH/$HADOOP_TARBALL.asc
  wget -nv -P $DOWNLOADS $APACHE/$ZOOKEEPER_PATH/$ZOOKEEPER_TARBALL.asc
  wget -nv -P $DOWNLOADS $APACHE/$SPARK_PATH/$SPARK_TARBALL.asc

  echo -e "\nVerifying the authenticity of tarballs using gpg and downloaded signatures:"
  if [ -z "$ACCUMULO_TARBALL_REPO" ]; then
    echo -e "\nVerifying $ACCUMULO_TARBALL" 
    gpg --verify $DOWNLOADS/$ACCUMULO_TARBALL.asc $DOWNLOADS/$ACCUMULO_TARBALL
  fi
  echo -e "\nverifying $HADOOP_TARBALL" 
  gpg --verify $DOWNLOADS/$HADOOP_TARBALL.asc $DOWNLOADS/$HADOOP_TARBALL
  echo -e "\nVerifying $ZOOKEEPER_TARBALL" 
  gpg --verify $DOWNLOADS/$ZOOKEEPER_TARBALL.asc $DOWNLOADS/$ZOOKEEPER_TARBALL
  echo -e "\nVerifying $SPARK_TARBALL" 
  gpg --verify $DOWNLOADS/$SPARK_TARBALL.asc $DOWNLOADS/$SPARK_TARBALL
else
  echo -e "\nERROR - The command 'gpg' is NOT installed!  Please install to verify signatures of downloaded tarballs."
fi
