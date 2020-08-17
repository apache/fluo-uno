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

TARBALL_PATH=$PROXY_REPO/target/$PROXY_TARBALL

if [[ ! -f "$TARBALL_PATH" ]]; then
  cd $PROXY_REPO/
  mvn -V -e clean package -Ptarball
fi

print_to_console "Installing Accumulo Proxy at $PROXY_HOME"

tar xzf "$TARBALL_PATH" -C "$INSTALL"

$SED "s#instance[.]name=myinstance#instance.name=$ACCUMULO_INSTANCE#" "${PROXY_HOME}/conf/proxy.properties"
$SED "s#instance[.]zookeepers=localhost:2181#instance.zookeepers=$UNO_HOST:2181#" "${PROXY_HOME}/conf/proxy.properties"
$SED "s#auth[.]principal=#auth.principal=$ACCUMULO_USER#" "${PROXY_HOME}/conf/proxy.properties"
$SED "s#auth[.]token=#auth.token=$ACCUMULO_PASSWORD#" "${PROXY_HOME}/conf/proxy.properties"

mkdir -p "${INSTALL}/logs/accumulo-proxy"

pkill -f accumulo\\.proxy\\.Proxy

"$PROXY_HOME"/bin/accumulo-proxy -p "$PROXY_HOME"/conf/proxy.properties &> "${INSTALL}/logs/accumulo-proxy/accumulo-proxy.log" &

print_to_console "Accumulo Proxy $PROXY_VERSION is running"
print_to_console "    * view logs at $INSTALL/logs/accumulo-proxy/"
