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

source "$UNO_HOME"/bin/impl/util.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo >&0 "The metrics services (InfluxDB and Grafana) are not supported on Mac OS X at this time."
  exit 1
fi

echo >&0 "Killing InfluxDB & Grafana (if running)"
pkill -f influxdb
pkill -f grafana-server

# verify downloaded tarballs
INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
verify_exist_hash "$INFLUXDB_TARBALL" "$INFLUXDB_HASH"
verify_exist_hash "$GRAFANA_TARBALL" "$GRAFANA_HASH"

# make sure built tarballs exist
INFLUXDB_TARBALL=influxdb-"$INFLUXDB_VERSION".tar.gz
GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".tar.gz
if [[ ! -f "$DOWNLOADS/build/$INFLUXDB_TARBALL" ]]; then
  echo >&0 "InfluxDB tarball $INFLUXDB_TARBALL does not exists in downloads/build/"
  exit 1
fi
if [[ ! -f "$DOWNLOADS/build/$GRAFANA_TARBALL" ]]; then
  echo >&0 "Grafana tarball $GRAFANA_TARBALL does not exists in downloads/build"
  exit 1
fi

if [[ ! -d "$FLUO_HOME" ]]; then
  echo >&0 "Fluo must be installed before setting up metrics"
  exit 1
fi

# stop if any command fails
set -e

echo >&0 "Removing previous versions of InfluxDB & Grafana"
rm -rf "$INSTALL"/influxdb-*
rm -rf "$INSTALL"/grafana-*

echo >&0 "Remove previous log and data dirs"
rm -f "$LOGS_DIR"/metrics/*
rm -rf "$DATA_DIR"/influxdb
mkdir -p "$LOGS_DIR"/metrics

echo >&0 "Setting up metrics (influxdb + grafana)..."
tar xzf "$DOWNLOADS/build/$INFLUXDB_TARBALL" -C "$INSTALL"
"$INFLUXDB_HOME"/bin/influxd config -config "$UNO_HOME"/conf/influxdb/influxdb.conf > "$INFLUXDB_HOME"/influxdb.conf
if [[ ! -f "$INFLUXDB_HOME"/influxdb.conf ]]; then
  echo >&0 "Failed to create $INFLUXDB_HOME/influxdb.conf"
  exit 1
fi
$SED "s#DATA_DIR#$DATA_DIR#g" "$INFLUXDB_HOME"/influxdb.conf
"$INFLUXDB_HOME"/bin/influxd -config "$INFLUXDB_HOME"/influxdb.conf &> "$LOGS_DIR"/metrics/influxdb.log &

tar xzf "$DOWNLOADS/build/$GRAFANA_TARBALL" -C "$INSTALL"
cp "$UNO_HOME"/conf/grafana/custom.ini "$GRAFANA_HOME"/conf/
$SED "s#GRAFANA_HOME#$GRAFANA_HOME#g" "$GRAFANA_HOME"/conf/custom.ini
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$GRAFANA_HOME"/conf/custom.ini
mkdir "$GRAFANA_HOME"/dashboards
cp "$FLUO_HOME"/contrib/grafana/* "$GRAFANA_HOME"/dashboards/
cp "$UNO_HOME"/conf/grafana/accumulo-dashboard.json "$GRAFANA_HOME"/dashboards/
"$GRAFANA_HOME"/bin/grafana-server -homepath="$GRAFANA_HOME" 2> /dev/null &

echo >&0 "Configuring Fluo to send metrics to InfluxDB"
if [[ $FLUO_VERSION =~ ^1\.[0-1].*$ ]]; then
  FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
else
  FLUO_PROPS=$FLUO_HOME/conf/fluo-app.properties
fi

$SED "/fluo.metrics.reporter.graphite/d" "$FLUO_PROPS"
{
  echo "fluo.metrics.reporter.graphite.enable=true"
  echo "fluo.metrics.reporter.graphite.host=$UNO_HOST"
  echo "fluo.metrics.reporter.graphite.port=2003"
  echo "fluo.metrics.reporter.graphite.frequency=30"
} >> "$FLUO_PROPS"

echo >&0 "Configuring InfluxDB..."
sleep 10
"$INFLUXDB_HOME"/bin/influx -import -path "$FLUO_HOME"/contrib/influxdb/fluo_metrics_setup.txt

# allow commands to fail
set +e

echo >&0 "Configuring Grafana..."

sleep 5

function add_datasource() {
  retcode=1
  while [[ $retcode != 0 ]];  do
    curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary "$1"
    retcode=$?
    if [[ $retcode != 0 ]]; then
      echo >&0 "Failed to add Grafana data source. Retrying in 5 sec.."
      sleep 5
    fi
  done
  echo >&0 ""
}

accumulo_data='{"name":"accumulo_metrics","type":"influxdb","url":"http://'
accumulo_data+=$UNO_HOST
accumulo_data+=':8086","access":"direct","isDefault":true,"database":"accumulo_metrics","user":"accumulo","password":"secret"}'
add_datasource $accumulo_data

fluo_data='{"name":"fluo_metrics","type":"influxdb","url":"http://'
fluo_data+=$UNO_HOST
fluo_data+=':8086","access":"direct","isDefault":false,"database":"fluo_metrics","user":"fluo","password":"secret"}'
add_datasource $fluo_data

stty sane
