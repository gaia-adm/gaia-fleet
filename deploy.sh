#!/bin/bash

# debug
# set -x

# export FLEETCTL_ENDPOINT: docker host IP and 4001 port
if [ -z "$FLEETCTL_ENDPOINT" ]; then
  export FLEETCTL_ENDPOINT=http://$(netstat -nr | grep '^0\.0\.0\.0' | awk '{ print $2 }'):4001
fi


# start fleet unit and wait till 'active' and 'running'
function start_fleet_unit() {
  fleetctl start $1
  # skip vault-unseal unit wait (it's a volume container)
  if [ $1 == "vault-unseal.service" ]; then
    return 0
  fi
  # ACTIVE status is 'active' or 3 min timeout
  local status=0
  while [ $status -lt 60 ] ;do
    sleep 3
    if [ $(fleetctl list-units | grep -cw $1) != 0 ]; then
      x=$(fleetctl list-units | grep -w $1 | awk '{print $3}')
      for i in ${x[@]}; do
        if [ $i == "active" ]; then
          status=60
          break
        fi
      done
    fi
    status=$((status+1))
 done
}


# submit new/updates fleet units and destroy previous versions, if exist
function load_fleet_unit() {
  if [[ $(fleetctl list-unit-files | grep -w ${1}) ]]; then
    fleetctl submit ${1} 1&> .tmp
    if cat .tmp | grep -q "differs"; then
      fleetctl destroy ${1}
      fleetctl submit ${1}
      echo "${1} - unit had beed updated"
    else
      echo "${1} - update is not required"
    fi
    rm .tmp
  else
    fleetctl submit ${1}
    echo "${1} - a new unit uploaded"
  fi
}


# destroy fleet units without files
function cleanup_fleet_units() {
  for file in $(fleetctl list-unit-files -fields unit --no-legend); do
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


# deploy = load and start fleet unit
function deploy_fleet_unit() {
  load_fleet_unit $1
  start_fleet_unit $1
}


declare -a core_units=( skydns.service registrator.service postgres.service cadvisor.service logentries.service vault.service vault-unseal.service result-upload-service.service )
declare -a all_units=(*.service)
declare -a other_units=()

for u in ${all_units[@]}; do
  found=1
  for c in ${core_units[@]}; do
    if [ $c == $u ]; then
      found=0
    fi
  done
  if [[ $found == 1 ]]; then
    # for template add two units
    if [[ $u =~ "@.service" ]]; then
      other_units+=(${u/@.service/@1.service})
      if [[ $(fleetctl list-machines | grep -v MACHINE  | wc -l) -gt 1 ]]; then
        other_units+=(${u/@.service/@2.service})
      fi
    else
      other_units+=($u)
    fi
  fi
done

units=( ${core_units[@]} ${other_units[@]} )

isAWS=$(systemctl show-environment | grep AWS_ | wc -l) 


for unit in ${units[@]}; do
  echo "depoyment of: $unit"
  if { [[ isAWS -eq 2 ]] && [[ $unit =~ ".vagrant.service" ]]; }; then
    deploy_fleet_unit $unit
  else
    echo deployment is not needed on AWS environment
  fi
done


# cleanup units that do not have corresponding file
cleanup_fleet_units
