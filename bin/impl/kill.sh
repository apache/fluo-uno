#! /usr/bin/env bash

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

# Start: Resolve Script Directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
   impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
   SOURCE="$(readlink "$SOURCE")"
   [[ $SOURCE != /* ]] && SOURCE="$impl/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
impl="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
script=$( basename "$SOURCE" )
# Stop: Resolve Script Directory

case "$1" in
hadoop)
  pkill -f accumulo.start
  pkill -f hadoop.hdfs
  pkill -f hadoop.yarn
	;;
zookeeper)
  pkill -f QuorumPeerMain
	;;
accumulo)
  pkill -f accumulo.start
	;;
fluo)
  pkill -f fluo.yarn
  pkill -f MiniFluo
	;;
all)
  pkill -f fluo.yarn
  pkill -f MiniFluo
  pkill -f accumulo.start
  pkill -f hadoop.hdfs
  pkill -f hadoop.yarn
  pkill -f QuorumPeerMain
  ;;
*)
	echo -e "Usage: fluo-dev kill <argument>\n"
  echo -e "Possible arguments:\n"
  echo "  hadoop      Kills Hadoop"
  echo "  zookeeper   Kills Zookeeper"
  echo "  accumulo    Kills Accumulo"
  echo "  fluo        Kills Fluo"
  echo "  all         Kill all of the above"
  exit 1
esac
