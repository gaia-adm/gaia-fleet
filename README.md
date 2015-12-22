# Gaia Fleet

This repository contains a set of services for Gaia ADM project.

## Build

To build current image behind corporate proxy use `--build-arg` option (introduced with Docker 1.9)

## Initilization

Once you have a CoreOS cluster up and running, you will need to deploy `skydns.service` and `registrator.service` to the cluster.

```
fleetctl submit skydns.service
fleetctl submit registrator.service
fleetctl start skydns
fleetctl start registrator
```

After you have [SkyDNS](https://github.com/skynetservices/skydns) and [Registrator](https://github.com/gliderlabs/registrator) up and running on each cluster node, you can now deploy and auto-register any other fleet service.
You do not need to do anything special, while running your service in Docker, beside specifying name with `--name` parameter or setting `SERVICE_NAME` environment variable.

For example:
```
/usr/bin/docker run --name rabbitmq-%i -p 5672:5672 -p 15672:15672 -e "SERVICE_NAME=rabbitmq-%i" -e "SERVICE_TAGS=master" gaiaadm/rabbitmq:3.5.3-1

```

## DNS setup

If you are using [our fork](https://github.com/gaia-adm/coreos-vagrant) of [coreos-vagrant](https://github.com/coreos/coreos-vagrant), you do not need to specify DNS for every docker container you are running. The appropriate DNS server will be setup automatically for you container.
