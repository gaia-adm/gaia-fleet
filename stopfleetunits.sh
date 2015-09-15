#!/bin/bash

echo "*** Going to stop fleet units"

fleetctl stop skydns.service
fleetctl stop registrator.service
fleetctl stop influxdb.data.service
fleetctl stop influxdb.service
fleetctl stop grafana.service
fleetctl stop rabbitmq.data@master.service
fleetctl stop rabbitmq@master.service
fleetctl stop events-indexer.service
fleetctl stop metrics-gateway-service.service
fleetctl stop security-token-service.service
fleetctl stop result-upload-service.service
fleetctl stop sample-weather-processor.service
fleetctl stop circleci-tests-processor.service
fleetctl stop jenkins-tests-processor.service
fleetctl stop haproxy.service
