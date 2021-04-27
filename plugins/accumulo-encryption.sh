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

if [[ $ACCUMULO_VERSION =~ ^1\..*$ ]]; then
  echo "Encryption cannot be enabled for Accumulo 1.x"
  exit 1
fi

accumulo_conf=$ACCUMULO_HOME/conf/accumulo.properties
encrypt_key=$ACCUMULO_HOME/conf/data-encryption.key
openssl rand -out $encrypt_key 32
echo "instance.crypto.opts.key.uri=file://$encrypt_key" >> "$accumulo_conf"
echo "instance.crypto.service=$(jar -tvf "$ACCUMULO_HOME"/lib/accumulo-core-2.*.jar | grep -o 'org.apache.accumulo.core.*AESCryptoService' | tr / . | tail -1)" >> "$accumulo_conf"
