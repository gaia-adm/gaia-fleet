[![Circle CI](https://circleci.com/gh/gaia-adm/gaia-fleet.svg?style=svg)](https://circleci.com/gh/gaia-adm/gaia-fleet)
[![](https://badge.imagelayers.io/gaiaadm/gaia-fleet:latest.svg)](https://imagelayers.io/?images=gaiaadm/gaia-fleet:latest 'Get your own badge on imagelayers.io')

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

## Deploy and Update Gaia Services on CoreOS cluster

`gaia-fleet` container requires `fleetctl` Fleet client to be avaiable inside the container. The idea is to use `fleetctl` from host machine, adding volume mapping `-v /usr/bin/fleetctl:/usr/bin/fleetctl` to `docker run` command.

In order to deply and update Gaia services on CoreOS cluster run the command bellow on one of the cluster hosts.
* For AWS:
```
docker run -it --rm --name=gaiacd -v /usr/bin/fleetctl:/usr/bin/fleetctl gaiaadm/gaia-fleet:<TAG>
```
* For vagrant:
```
docker run -it --rm -e environ=vagrant --name=gaiacd -v /usr/bin/fleetctl:/usr/bin/fleetctl gaiaadm/gaia-fleet:<TAG>
```
where <TAG> is something like 561-master.  
To watch the deployment progress you can run the following command inside other SSH session on any machine that can conect to CoreOS cluster.

```
whatch -n 3 `fleetctl list-unit-files && echo "====================" && fleetctl list-units`
```

**Note 1**: When gaia-fleet is updated automatically from non-master branches of other repositories, the "latest" tag points to non-master default; in order to run the latest image of master branch, "master" tag should be mentioned explicitely.

**Note 2**: This feature is under development and the deployment procedure will be changed soon.

## DNS setup

If you are using [our fork](https://github.com/gaia-adm/coreos-vagrant) of [coreos-vagrant](https://github.com/coreos/coreos-vagrant), you do not need to specify DNS for every docker container you are running. The appropriate DNS server will be setup automatically for you container.
