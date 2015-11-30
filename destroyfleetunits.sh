#!/bin/bash
# This is an helper script that destroy fleet units
# You should use it if you want to rerun the units initialization

echo "*** Going to destroy fleet units"

fleetctl destroy skydns.service
fleetctl destroy registrator.service
fleetctl destroy influxdb.service
fleetctl destroy grafana.service
fleetctl destroy es.service
fleetctl destroy kibana.service
fleetctl destroy rabbitmq@master.service
fleetctl destroy rabbitmq@.service
fleetctl destroy events-indexer.service
fleetctl destroy es-events-indexer.service
fleetctl destroy metrics-gateway-service.service
fleetctl destroy security-token-service.service
fleetctl destroy result-upload-service.service
fleetctl destroy sample-weather-processor.service
fleetctl destroy circleci-tests-processor.service
fleetctl destroy jenkins-tests-processor.service 
fleetctl destroy alm-issue-change-processor.service
fleetctl destroy agm-issue-change-processor.service
fleetctl destroy haproxy.service
