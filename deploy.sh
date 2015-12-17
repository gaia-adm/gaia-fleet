#!/bin/bash

# debug
set -x

# export FLEETCTL_ENDPOINT: docker host IP and 4001 port
if [ -z "$FLEETCTL_ENDPOINT" ]; then
  export FLEETCTL_ENDPOINT=http://$(netstat -nr | grep '^0\.0\.0\.0' | awk '{ print $2 }'):4001
fi

# start all 'loaded' unit files
function start_loaded_fleet_units() {
  local x=`fleetctl list-unit-files | grep -w inactive | awk '{print $1}'`
  local loadedArr=(${x//$'\n'/ })
  for s in "${loadedArr[@]}"; do
    fleetctl start $s
  done
}

# start fleet unit and wait till 'active' and 'running'
function start_fleet_unit() {
  fleetctl start $1
  status=1
  while [ $status -eq 1 ] ;do
    status=0
    local x=`fleetctl list-units | grep -w ${1} | awk '{print $3}'`
    local statusArr=(${x//$'\n'/ })
    for i in "${statusArr[@]}"; do
      status=`${status} || [ $i == "active" ]`
    done
    sleep 5
  done
}


# submit new/updates fleet units and destroy previous versions, if exist
function load_fleet_unit() {
  if [ `fleetctl list-unit-files | grep -q $1` ]; then
    fleetctl submit $1 1&> .tmp
    if [ `cat .tmp | grep -q "differs"` ]; then
      fleetctl destroy $1
      fleetctl submit $1
      echo "${1} - unit had beed updated\n"
    else
      echo "${1} - update is not required\n"
    fi
    rm .tmp
  else
    fleetctl submit $1
    echo "${1} - a new unit uploaded"
  fi
}


# deploy = load and start fleet unit
function deploy_fleet_unit() {
  load_fleet_unit $1
  start_fleet_unit $1
}


# destroy fleet units without files
function cleanup_fleet_units() {
  for file in `fleetctl list-unit-files -fields unit --no-legend`; do
    if [ -f $file ]; then
      continue
    else
      # handle template
      if [[ $file =~ "@" ]]; then
        local template=${file%%@*}@.service
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

# 1: deploy/update SkyDNS
deploy_fleet_unit skydns.service

# 2: deploy/update Registrator
deploy_fleet_unit registrator.service

# 3: deploy/update cAdvisor
deploy_fleet_unit cadvisor.service

# 4: deploy/update logentries
deploy_fleet_unit logentries.service

# 5: deploy vault
deploy_fleet_unit vault.service
deploy_fleet_unit vault-unseal.service

# 6: TEMP run result-upload-service before all 'processors'
deploy_fleet_unit result-upload-service.service

# deploy remaining units from all *.service files
# run 2 instances per template
for f in *.service; do
  if [[ $f =~ "@.service" ]]; then
    # deploy 2 instances per templates
    f1=${f/@.service/@master.service}
    f2=${f/@.service/@slave.service}
    load_fleet_unit $f1
    load_fleet_unit $f2
  else
    load_fleet_unit $f
  fi
done

# start all loaded units that are not running
start_loaded_fleet_units

# cleanup units that do not have corresponding file
cleanup_fleet_units
