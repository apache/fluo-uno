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

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "The metrics services (InfluxDB and Grafana) are not supported on Mac OS X at this time."
  exit 1
fi

pkill -f influxdb
pkill -f grafana-server

# stop if any command fails
set -e

BUILD=$DOWNLOADS/build
mkdir -p "$BUILD"

if [[ ! -f "$BUILD/$INFLUXDB_TARBALL" ]]; then
  IF_DIR=influxdb-$INFLUXDB_VERSION
  IF_PATH=$BUILD/$IF_DIR
  influx_tarball=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
  download_tarball https://s3.amazonaws.com/influxdb "$influx_tarball" "$INFLUXDB_HASH"
  tar xzf "$DOWNLOADS/$influx_tarball" -C "$BUILD"
  mv "$BUILD/influxdb_${INFLUXDB_VERSION}_x86_64" "$IF_PATH"
  mkdir "$IF_PATH"/bin
  mv "$IF_PATH/opt/influxdb/versions/$INFLUXDB_VERSION"/* "$IF_PATH"/bin
  rm -rf "$IF_PATH"/opt
  cd "$BUILD"
  tar czf influxdb-"$INFLUXDB_VERSION".tar.gz "$IF_DIR"
  rm -rf "$IF_PATH"
fi

if [[ ! -f "$BUILD/$GRAFANA_TARBALL" ]]; then
  GF_DIR=grafana-$GRAFANA_VERSION
  GF_PATH=$BUILD/$GF_DIR
  graf_tarball=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
  download_tarball https://grafanarel.s3.amazonaws.com/builds "$graf_tarball" "$GRAFANA_HASH"
  tar xzf "$DOWNLOADS/$graf_tarball" -C "$BUILD"
  cd "$BUILD"
  tar czf grafana-"$GRAFANA_VERSION".tar.gz "$GF_DIR"
  rm -rf "$GF_PATH"
fi

rm -rf "$INSTALL"/influxdb-*
rm -rf "$INSTALL"/grafana-*
rm -f "$LOGS_DIR"/metrics/*
rm -rf "$DATA_DIR"/influxdb
mkdir -p "$LOGS_DIR"/metrics

echo "Installing InfluxDB $INFLUXDB_VERSION to $INFLUXDB_HOME"

tar xzf "$DOWNLOADS/build/$INFLUXDB_TARBALL" -C "$INSTALL"
"$INFLUXDB_HOME"/bin/influxd config -config "$UNO_HOME"/plugins/influx-metrics/influxdb.conf > "$INFLUXDB_HOME"/influxdb.conf
if [[ ! -f "$INFLUXDB_HOME"/influxdb.conf ]]; then
  print_to_console "Failed to create $INFLUXDB_HOME/influxdb.conf"
  exit 1
fi
$SED "s#DATA_DIR#$DATA_DIR#g" "$INFLUXDB_HOME"/influxdb.conf

echo "Installing Grafana $GRAFANA_VERSION to $GRAFANA_HOME"

tar xzf "$DOWNLOADS/build/$GRAFANA_TARBALL" -C "$INSTALL"
cp "$UNO_HOME"/plugins/influx-metrics/custom.ini "$GRAFANA_HOME"/conf/
$SED "s#GRAFANA_HOME#$GRAFANA_HOME#g" "$GRAFANA_HOME"/conf/custom.ini
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$GRAFANA_HOME"/conf/custom.ini
mkdir "$GRAFANA_HOME"/dashboards

if [[ -d "$ACCUMULO_HOME" ]]; then
  echo "Configuring Accumulo metrics"
  cp "$UNO_HOME"/plugins/influx-metrics/accumulo-dashboard.json "$GRAFANA_HOME"/dashboards/
  conf=$ACCUMULO_HOME/conf
  metrics_props=hadoop-metrics2-accumulo.properties
  cp "$conf"/templates/"$metrics_props" "$conf"/
  $SED "/accumulo.sink.graphite/d" "$conf"/"$metrics_props"
  {
    echo "accumulo.sink.graphite.class=org.apache.hadoop.metrics2.sink.GraphiteSink"
    echo "accumulo.sink.graphite.server_host=localhost"
    echo "accumulo.sink.graphite.server_port=2004"
    echo "accumulo.sink.graphite.metrics_prefix=accumulo"
  } >> "$conf"/"$metrics_props"
fi

if [[ -d "$FLUO_HOME" ]]; then
  echo "Configuring Fluo metrics"
  cp "$FLUO_HOME"/contrib/grafana/* "$GRAFANA_HOME"/dashboards/
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
fi

"$INFLUXDB_HOME"/bin/influxd -config "$INFLUXDB_HOME"/influxdb.conf &> "$LOGS_DIR"/metrics/influxdb.log &

"$GRAFANA_HOME"/bin/grafana-server -homepath="$GRAFANA_HOME" 2> /dev/null &

sleep 10

if [[ -d "$FLUO_HOME" ]]; then
  "$INFLUXDB_HOME"/bin/influx -import -path "$FLUO_HOME"/contrib/influxdb/fluo_metrics_setup.txt
fi

# allow commands to fail
set +e

sleep 5

function add_datasource() {
  retcode=1
  while [[ $retcode != 0 ]];  do
    curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary "$1"
    retcode=$?
    if [[ $retcode != 0 ]]; then
      print_to_console "Failed to add Grafana data source. Retrying in 5 sec.."
      sleep 5
    fi
  done
  echo ""
}

if [[ -d "$ACCUMULO_HOME" ]]; then
  accumulo_data='{"name":"accumulo_metrics","type":"influxdb","url":"http://'
  accumulo_data+=$UNO_HOST
  accumulo_data+=':8086","access":"direct","isDefault":true,"database":"accumulo_metrics","user":"accumulo","password":"secret"}'
  add_datasource $accumulo_data
fi

if [[ -d "$FLUO_HOME" ]]; then
  fluo_data='{"name":"fluo_metrics","type":"influxdb","url":"http://'
  fluo_data+=$UNO_HOST
  fluo_data+=':8086","access":"direct","isDefault":false,"database":"fluo_metrics","user":"fluo","password":"secret"}'
  add_datasource $fluo_data
fi

stty sane

print_to_console "InfluxDB $INFLUXDB_VERSION is running"
print_to_console "Grafana $GRAFANA_VERSION is running"
print_to_console "    * UI: http://$UNO_HOST:3000/"

stty sane
