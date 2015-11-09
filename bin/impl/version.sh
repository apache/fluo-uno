
case "$1" in
hadoop)
  echo -n $HADOOP_VERSION
  ;;
zookeeper)
  echo -n $ZOOKEEPER_VERSION
  ;;
accumulo)
  echo -n $ACCUMULO_VERSION
  ;;
fluo)
  echo -n $FLUO_VERSION
  ;;
spark)
  echo -n $SPARK_VERSION
  ;;
influxdb)
  echo -n $INFLUXDB_VERSION
  ;;
grafana)
  echo -n $GRAFANA_VERSION
  ;;
*)
  echo "You must specify a valid depedency (i.e hadoop, zookeeper, accumulo, etc)"
  exit 1
esac
