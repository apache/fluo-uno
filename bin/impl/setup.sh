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

function verify_exist_hash() {
  tarball=$1
  expected_md5=$2
  actual_md5=`$MD5 $DOWNLOADS/$tarball | awk '{print $1}'`

  if [ ! -f "$DOWNLOADS/$tarball" ]; then
    echo "The tarball $tarball does not exists in downloads/"
    exit 1
  fi
  if [[ "$actual_md5" != "$expected_md5" ]]; then
    echo "The MD5 checksum ($actual_md5) of $tarball does not match the expected checksum ($expected_md5)"
    exit 1
  fi
}

if [ -z "$ACCUMULO_TARBALL_REPO" ]; then
  verify_exist_hash $ACCUMULO_TARBALL $ACCUMULO_MD5
fi
verify_exist_hash $HADOOP_TARBALL $HADOOP_MD5
verify_exist_hash $ZOOKEEPER_TARBALL $ZOOKEEPER_MD5
verify_exist_hash $SPARK_TARBALL $SPARK_MD5

host `hostname` &> /dev/null
if [ $? != 0 ]; then
  echo "ERROR - Your machine failed to do a DNS lookup of your IP given your hostname using 'host `hostname`'.  This is likely a DNS issue"
  echo "that can cause fluo-dev services (such as Hadoop) to not start up.  You should confirm that /etc/resolv.conf is correct."
  exit 1
fi

if [ $SETUP_METRICS = "true" ]; then
  # verify downloaded tarballs
  INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
  verify_exist_hash $INFLUXDB_TARBALL $INFLUXDB_MD5
  verify_exist_hash $GRAFANA_TARBALL $GRAFANA_MD5

  # make sure built tarballs exist
  INFLUXDB_TARBALL=influxdb-"$INFLUXDB_VERSION".tar.gz
  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".tar.gz
  if [ ! -f "$DOWNLOADS/build/$INFLUXDB_TARBALL" ]; then
    echo "InfluxDB tarball $INFLUXDB_TARBALL does not exists in downloads/build/"
    exit 1
  fi
  if [ ! -f "$DOWNLOADS/build/$GRAFANA_TARBALL" ]; then
    echo "Grafana tarball $GRAFANA_TARBALL does not exists in downloads/build"
    exit 1
  fi
fi

$FLUO_DEV/bin/impl/kill.sh

# stop if any command fails
set -e

echo "Removing previous versions of Hadoop, Zookeeper, Accumulo & Spark"
rm -rf $INSTALL/accumulo-*
rm -rf $INSTALL/hadoop-*
rm -rf $INSTALL/zookeeper-*
rm -rf $INSTALL/spark-*
rm -rf $INSTALL/influxdb-*
rm -rf $INSTALL/grafana-*

echo "Installing Hadoop, Zookeeper, Accumulo & Spark to $INSTALL"
tar xzf $DOWNLOADS/$ACCUMULO_TARBALL -C $INSTALL
tar xzf $DOWNLOADS/$HADOOP_TARBALL -C $INSTALL
tar xzf $DOWNLOADS/$ZOOKEEPER_TARBALL -C $INSTALL
tar xzf $DOWNLOADS/$SPARK_TARBALL -C $INSTALL

echo "Configuring..."
# configure hadoop
cp $FLUO_DEV/conf/hadoop/* $HADOOP_PREFIX/etc/hadoop/
cp $SPARK_HOME/lib/spark-$SPARK_VERSION-yarn-shuffle.jar $HADOOP_PREFIX/share/hadoop/yarn/lib/
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
$SED "s#DATA_DIR#$DATA_DIR#g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
$SED "s#YARN_LOGS#$HADOOP_PREFIX/logs#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_MEM_MB#$YARN_NM_MEM_MB#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
$SED "s#YARN_NM_CPU_VCORES#$YARN_NM_CPU_VCORES#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# configure zookeeper
cp $FLUO_DEV/conf/zookeeper/* $ZOOKEEPER_HOME/conf/
$SED "s#DATA_DIR#$DATA_DIR#g" $ZOOKEEPER_HOME/conf/zoo.cfg

# configure accumulo
cp $ACCUMULO_HOME/conf/examples/2GB/standalone/* $ACCUMULO_HOME/conf/
cp $FLUO_DEV/conf/accumulo/* $ACCUMULO_HOME/conf/
$SED "s#export ZOOKEEPER_HOME=[^ ]*#export ZOOKEEPER_HOME=$ZOOKEEPER_HOME#" $ACCUMULO_HOME/conf/accumulo-env.sh
$SED "s#export HADOOP_PREFIX=[^ ]*#export HADOOP_PREFIX=$HADOOP_PREFIX#" $ACCUMULO_HOME/conf/accumulo-env.sh
$SED "s#ACCUMULO_TSERVER_OPTS=.*#ACCUMULO_TSERVER_OPTS=\"-Xmx$ACCUMULO_TSERV_MEM -Xms$ACCUMULO_TSERV_MEM\"#" $ACCUMULO_HOME/conf/accumulo-env.sh
$SED "s#ACCUMULO_DCACHE_SIZE#$ACCUMULO_DCACHE_SIZE#" $ACCUMULO_HOME/conf/accumulo-site.xml
$SED "s#ACCUMULO_ICACHE_SIZE#$ACCUMULO_ICACHE_SIZE#" $ACCUMULO_HOME/conf/accumulo-site.xml
$SED "s#ACCUMULO_IMAP_SIZE#$ACCUMULO_IMAP_SIZE#" $ACCUMULO_HOME/conf/accumulo-site.xml

# configure spark
cp $FLUO_DEV/conf/spark/* $SPARK_HOME/conf
$SED "s#DATA_DIR#$DATA_DIR#g" $SPARK_HOME/conf/spark-defaults.conf
$SED "s#HADOOP_PREFIX#$HADOOP_PREFIX#g" $SPARK_HOME/conf/spark-env.sh

echo "Starting Spark HistoryServer..."
rm -rf $DATA_DIR/spark
mkdir -p $DATA_DIR/spark/events
if [ $START_SPARK_HIST_SERVER = "true" ]; then
  $SPARK_HOME/sbin/start-history-server.sh
fi

echo "Starting Hadoop..."
rm -rf $HADOOP_PREFIX/logs/*
rm -rf $DATA_DIR/hadoop
$HADOOP_PREFIX/bin/hdfs namenode -format
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh

echo "Starting Zookeeper..."
rm -f $ZOOKEEPER_HOME/zookeeper.out
rm -rf $DATA_DIR/zookeeper
export ZOO_LOG_DIR=$ZOOKEEPER_HOME
$ZOOKEEPER_HOME/bin/zkServer.sh start

echo "Starting Accumulo..."
rm -f $ACCUMULO_HOME/logs/*
$HADOOP_PREFIX/bin/hadoop fs -rm -r /accumulo 2> /dev/null || true
$ACCUMULO_HOME/bin/accumulo init --clear-instance-name --instance-name $ACCUMULO_INSTANCE --password $ACCUMULO_PASSWORD
$ACCUMULO_HOME/bin/start-all.sh

echo "Setting up Fluo"
$FLUO_DEV/bin/impl/redeploy.sh

if [ $SETUP_METRICS = "true" ]; then
  echo "Setting up metrics (influxdb + grafana)..."
  tar xzf $DOWNLOADS/build/$INFLUXDB_TARBALL -C $INSTALL
  $INFLUXDB_HOME/bin/influxd config -config $FLUO_DEV/conf/influxdb/influxdb.conf > $INFLUXDB_HOME/influxdb.conf
  if [ ! -f $INFLUXDB_HOME/influxdb.conf ]; then
    echo "Failed to create $INFLUXDB_HOME/influxdb.conf"
    exit 1
  fi
  $SED "s#DATA_DIR#$DATA_DIR#g" $INFLUXDB_HOME/influxdb.conf
  rm -rf $DATA_DIR/influxdb
  $INFLUXDB_HOME/bin/influxd -config $INFLUXDB_HOME/influxdb.conf &> $INFLUXDB_HOME/influxdb.log &

  tar xzf $DOWNLOADS/build/$GRAFANA_TARBALL -C $INSTALL
  cp $FLUO_DEV/conf/grafana/custom.ini $GRAFANA_HOME/conf/
  $SED "s#GRAFANA_HOME#$GRAFANA_HOME#g" $GRAFANA_HOME/conf/custom.ini
  mkdir $GRAFANA_HOME/dashboards
  cp $FLUO_HOME/contrib/grafana/* $GRAFANA_HOME/dashboards/
  $GRAFANA_HOME/bin/grafana-server -homepath=$GRAFANA_HOME &> $GRAFANA_HOME/grafana.log &

  echo "Configuring InfluxDB..."
  sleep 10
  $INFLUXDB_HOME/bin/influx -execute "CREATE USER fluo WITH PASSWORD 'secret' WITH ALL PRIVILEGES"

  # allow commands to fail
  set +e

  echo "Configuring Grafana..."
  echo "Adding InfluxDB as datasource"
  sleep 10
  retcode=1
  while [ $retcode != 0 ];  do
    curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary '{"name":"fluo_metrics","type":"influxdb","url":"http://localhost:8086","access":"direct","isDefault":true,"database":"fluo_metrics","user":"fluo","password":"secret"}'
    retcode=$?
    if [ $retcode != 0 ]; then
      echo "Failed to add Grafana data source.  Retrying in 5 sec.."
      sleep 5
    fi
  done 
fi

echo -e "\nSetup is finished!"
