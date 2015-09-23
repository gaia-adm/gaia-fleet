#!/bin/bash
echo "*** Submiting and Starting fleet units"

fleetctl submit ./*.service

fleetctl start skydns.service
fleetctl start registrator.service
fleetctl start influxdb.data.service
fleetctl start influxdb.service
fleetctl start grafana.service
fleetctl start rabbitmq.data@master.service
fleetctl start rabbitmq@master.service
fleetctl start events-indexer.service
fleetctl start security-token-service.service
fleetctl start metrics-gateway-service.service
fleetctl start result-upload-service.service
fleetctl start sample-weather-processor.service
fleetctl start circleci-tests-processor.service
fleetctl start jenkins-tests-processor.service
fleetctl start alm-issue-change-processor.service
fleetctl start agm-issue-change-processor.service
fleetctl start haproxy.service
