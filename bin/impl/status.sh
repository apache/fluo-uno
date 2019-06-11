#! /usr/bin/env bash

tmp="$(pgrep -f hadoop\\.hdfs | tr '\n' ' ')"
if [[ "$tmp" ]]; then
        echo "Hadoop is running at: $tmp"
fi

tmp="$(pgrep -f QuorumPeerMain | tr '\n' ' ')"
if [[ "$tmp"  ]]; then
        echo "Zookeeper is running at: $tmp "
fi

tmp="$(pgrep -f accumulo\\.start | tr '\n' ' ')"
if [[ "$tmp"  ]]; then
        echo "Accumulo is running at: $tmp"
fi
