#! /usr/bin/env bash

# Copyright 2014 Uno authors (see AUTHORS)
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

source $FLUO_DEV/bin/impl/util.sh

"$FLUO_DEV"/bin/impl/kill.sh

if [[ "$SETUP_METRICS" == "true" ]]; then
  # verify downloaded tarballs
  INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
  verify_exist_hash "$INFLUXDB_TARBALL" "$INFLUXDB_HASH"
  verify_exist_hash "$GRAFANA_TARBALL" "$GRAFANA_HASH"

  # make sure built tarballs exist
  INFLUXDB_TARBALL=influxdb-"$INFLUXDB_VERSION".tar.gz
  GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".tar.gz
  if [[ ! -f "$DOWNLOADS/build/$INFLUXDB_TARBALL" ]]; then
    echo "InfluxDB tarball $INFLUXDB_TARBALL does not exists in downloads/build/"
    exit 1
  fi
  if [[ ! -f "$DOWNLOADS/build/$GRAFANA_TARBALL" ]]; then
    echo "Grafana tarball $GRAFANA_TARBALL does not exists in downloads/build"
    exit 1
  fi
fi

# stop if any command fails
set -e

echo "Setting up Accumulo"
"$FLUO_DEV"/bin/impl/setup-accumulo.sh

echo "Setting up Fluo"
"$FLUO_DEV"/bin/impl/setup-fluo-only.sh

if [[ "$SETUP_METRICS" == "true" ]]; then
  echo "Removing previous versions of InfluxDB & Grafana"
  rm -rf "$INSTALL"/influxdb-*
  rm -rf "$INSTALL"/grafana-*

  echo "Remove previous log dirs and recreate"
  rm -f "$LOGS_DIR"/metrics/*
  mkdir -p "$LOGS_DIR"/metrics

  echo "Setting up metrics (influxdb + grafana)..."
  tar xzf "$DOWNLOADS"/build/"$INFLUXDB_TARBALL" -C "$INSTALL"
  "$INFLUXDB_HOME"/bin/influxd config -config "$FLUO_DEV"/conf/influxdb/influxdb.conf > "$INFLUXDB_HOME"/influxdb.conf
  if [[ ! -f "$INFLUXDB_HOME"/influxdb.conf ]]; then
    echo "Failed to create $INFLUXDB_HOME/influxdb.conf"
    exit 1
  fi
  $SED "s#DATA_DIR#$DATA_DIR#g" "$INFLUXDB_HOME"/influxdb.conf
  rm -rf "$DATA_DIR"/influxdb
  "$INFLUXDB_HOME"/bin/influxd -config "$INFLUXDB_HOME"/influxdb.conf &> "$LOGS_DIR"/metrics/influxdb.log &

  tar xzf "$DOWNLOADS"/build/"$GRAFANA_TARBALL" -C "$INSTALL"
  cp "$FLUO_DEV"/conf/grafana/custom.ini "$GRAFANA_HOME"/conf/
  $SED "s#GRAFANA_HOME#$GRAFANA_HOME#g" "$GRAFANA_HOME"/conf/custom.ini
  $SED "s#LOGS_DIR#$LOGS_DIR#g" "$GRAFANA_HOME"/conf/custom.ini
  mkdir "$GRAFANA_HOME"/dashboards
  cp "$FLUO_HOME"/contrib/grafana/* "$GRAFANA_HOME"/dashboards/
  "$GRAFANA_HOME"/bin/grafana-server -homepath="$GRAFANA_HOME" 2> /dev/null &

  echo "Configuring InfluxDB..."
  sleep 10
  "$INFLUXDB_HOME"/bin/influx -import -path "$FLUO_HOME"/contrib/influxdb/fluo_metrics_setup.txt

  # allow commands to fail
  set +e

  echo "Configuring Grafana..."
  echo "Adding InfluxDB as datasource"
  sleep 10
  retcode=1
  while [[ $retcode != 0 ]];  do
    curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary '{"name":"fluo_metrics","type":"influxdb","url":"http://localhost:8086","access":"direct","isDefault":true,"database":"fluo_metrics","user":"fluo","password":"secret"}'
    retcode=$?
    if [[ $retcode != 0 ]]; then
      echo "Failed to add Grafana data source.  Retrying in 5 sec.."
      sleep 5
    fi
  done
fi

stty sane

echo -e "\nSetup is finished!"
