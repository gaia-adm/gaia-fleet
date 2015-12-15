#!/bin/bash

# export FLEETCTL_ENDPOINT: docker host IP and 4001 port
export FLEETCTL_ENDPOINT=http://$(netstat -nr | grep '^0\.0\.0\.0' | awk '{ print $2 }'):4001

# deploy fleet units
function deploy_fleet_unit() {
  if [ `fleetctl list-unit-files | grep -q $1` ]; then
    fleetctl submit $1 1&> .tmp
    if [ `cat .tmp | grep -q "differs"` ]; then
      fleetctl destroy $1
      fleetctl submit $1
      fleetctl start $1
      echo "${1} - had beed updated\n"
    else
      echo "${1} - update is not required\n"
    fi
    rm .tmp
  else
    fleetctl submit $1
    fleetctl start $1
    echo "${1} - started a new service"
  fi
}

# destroy fleet units without files
function cleanup_fleet_units() {
  for file in `fleetctl list-unit-files -fields unit --no-legend`; do
    if [ -f $file ]; then
      continue
    else
      # handle template
      if [[ $file =~ "@" ]]; then
        local template=${file%%[0-9]*}.service
        if [ -f $template ]; then
          continue
        else
          fleetctl destroy ${file}
        fi
      else
        fleetctl destroy ${file}
      fi
    fi
  done
}

# First: deploy/update SkyDNS
deploy_fleet_unit skydns.service

# Second: deploy/update Registrator
deploy_fleet_unit registrator.service

# deploy units from all *.service files (2 instances per template)
for f in *.service; do
  if [[ $f =~ "@.service" ]]; then
    # deploy 2 instances per templates
    f1=${f/@.service/@1.service}
    f2=${f/@.service/@2.service}
    deploy_fleet_unit $f1
    deploy_fleet_unit $f2
  else
    deploy_fleet_unit $f
  fi
done

# cleanup units that do not have corresponding file
cleanup_fleet_units
