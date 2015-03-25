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
echo "Killing current deployment"
pkill -f fluo.yarn
pkill -f MiniFluo
pkill -f twill.launcher

# after this stop if any command fails
set -e  

echo "Removing current deployment" 
rm -rf $HADOOP_PREFIX/logs/application_*

# Remove old deployment
rm -rf $FLUO_HOME

# Remove old tarball
TARBALL=$FLUO_REPO/modules/distribution/target/fluo-$FLUO_VERSION-bin.tar.gz
rm -f $TARBALL

echo "Rebuilding Fluo" 
# Create new tarball
cd $FLUO_REPO
mvn clean package -DskipTests -Daccumulo.version=$ACCUMULO_VERSION -Dhadoop.version=$HADOOP_VERSION

# Deploy new tarball
tar xzf $TARBALL -C $INSTALL/

echo "Copying conf/examples to conf/"
# Copy example config to deployment
cp $FLUO_HOME/conf/examples/* $FLUO_HOME/conf/

FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
echo "Configuring conf/fluo.properties"
$SED "s/io.fluo.client.accumulo.instance=/io.fluo.client.accumulo.instance=$ACCUMULO_INSTANCE/g" $FLUO_PROPS
$SED "s/io.fluo.client.accumulo.user=/io.fluo.client.accumulo.user=$ACCUMULO_USER/g" $FLUO_PROPS
$SED "s/io.fluo.client.accumulo.password=/io.fluo.client.accumulo.password=$ACCUMULO_PASSWORD/g" $FLUO_PROPS

echo "Configuring conf/fluo-env.sh"
$SED "s#HADOOP_PREFIX=/path/to/hadoop#HADOOP_PREFIX=$HADOOP_PREFIX#g" $FLUO_HOME/conf/fluo-env.sh
