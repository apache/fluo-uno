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

atmp="$(pgrep -f accumulo\\.start | tr '\n' ' ')"
htmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
ztmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"

if [[ "$atmp" || "$ztmp" || "$htmp" ]]; then
	if [[ "$atmp"  ]]; then
		echo "Accumulo is running at: $atmp"
	fi

	if [[ "$ztmp"  ]]; then
		echo "Zookeeper is running at: $ztmp "
	fi

	if [[ "$htmp" ]]; then
		echo "Hadoop is running at: $htmp"
	fi

else
	echo "No components runnning."
fi




