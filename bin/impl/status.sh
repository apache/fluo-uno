#! /usr/bin/env bash

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




