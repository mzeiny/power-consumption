#!/bin/bash

set -ex

docker stop $(docker ps -aq) || echo "no running containers"
docker rm $(docker ps -aq) || echo "no containers to remove"

docker run -d -p 27017:27017 --name mongodb -e MONGO_INITDB_DATABASE="powerapi" mongo:3
docker run --name=influxdb -d -p 8086:8086 -e INFLUXDB_DB="power_consumption" influxdb

sleep 10

docker run --privileged --name powerapi-sensor --privileged -td \
    --link mongodb \
    -v /sys:/sys \
    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
    -v /tmp/sensor_output:/tmp/sensor_output \
    -v /tmp/powerapi-sensor-reporting:/reporting powerapi/hwpc-sensor \
    -n server-sensor \
		-r "mongodb" -U "mongodb://mongodb:27017" -D powerapi -C server-sensor \
    -s "rapl" -o -e RAPL_ENERGY_PKG

sleep 10

docker run -td --name powerapi-formula --link mongodb --link influxdb powerapi/rapl-formula \
   -s \
   --input mongodb -u mongodb://mongodb -d powerapi -c server-sensor \
   --output influxdb --uri influxdb --port 8086 --db power_consumption --name grafana_output

sleep 30

(cd power-consumption/app-sensor && ./bin/run.sh)
docker run -d -p 3000:3000 --link influxdb grafana/grafana
