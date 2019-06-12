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



atmp="$(ps -ef | grep accumulo\\.start | awk '{print $NF "(" $2 ")"}' | tr '\n' ' ')"
htmp="$(ps -ef | grep -e hadoop\\.hdfs -e hadoop\\.yarn | tr '.' ' ' | awk '{print $NF "(" $2 ")"}' | tr '\n' ' ')"
ztmp="$(pgrep -f QuorumPeerMain | awk '{print "zoo(" $1 ")"}' | tr '\n' ' ')"

if [[ "$atmp" || "$ztmp" || "$htmp" ]]; then
	if [[ "$atmp"  ]]; then
		echo "Accumulo processes running: $atmp"	
	fi

	if [[ "$ztmp"  ]]; then
		echo "Zookeeper processes running: $ztmp "
	fi

	if [[ "$htmp" ]]; then
		echo "Hadoop processes running: $htmp"
	fi

else
	echo "No components runnning."
fi




