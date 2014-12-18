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

pkill -f accumulo.start

rm -f $ACCUMULO_HOME/logs/*

$HADOOP_PREFIX/bin/hadoop fs -rm -r /accumulo

$ACCUMULO_HOME/bin/accumulo init --clear-instance-name --instance-name $ACCUMULO_INSTANCE --password $ACCUMULO_PASSWORD

$ACCUMULO_HOME/bin/start-all.sh
