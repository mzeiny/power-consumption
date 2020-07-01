#!/bin/bash

set -ex

docker build . -t app-sensor

sudo docker run -d --privileged --network=host app-sensor
