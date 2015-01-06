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

# Stop current processes
if [ -d "$FLUO_HOME" ]; then
  $FLUO_HOME/bin/fluo yarn stop
fi
pkill -f fluo.yarn
pkill -f MiniFluo
pkill -f twill.launcher

# after this stop if any command fails
set -e  

rm -rf $HADOOP_PREFIX/logs/application_*

# Remove old deployment
rm -rf $FLUO_HOME

# Remove old tarball
TARBALL=$FLUO_REPO/modules/distribution/target/fluo-$FLUO_VERSION-bin.tar.gz
rm -f $TARBALL

# Create new tarball
cd $FLUO_REPO
mvn package -Daccumulo.version=$ACCUMULO_VERSION -Dhadoop.version=$HADOOP_VERSION

# Deploy new tarball
tar xzf $TARBALL -C $SOFTWARE/

# Copy example config to deployment
cp $FLUO_HOME/conf/examples/* $FLUO_HOME/conf/

# Overwrite with your config
cp $FLUO_DEV/conf/fluo/* $FLUO_HOME/conf/

# Copy your observers to deployment
cp $FLUO_DEV/conf/observers/* $FLUO_HOME/lib/observers/ || true
cp $FLUO_REPO/modules/stress/target/fluo-stress-$FLUO_VERSION.jar $FLUO_HOME/lib/observers/

# Start fluo
set +e
$FLUO_HOME/bin/fluo init --force
while [ $? -ne 0 ]; do
  echo "Will try again in 5 sec"
  sleep 5
  $FLUO_HOME/bin/fluo init --force
done

$FLUO_HOME/bin/fluo yarn start
