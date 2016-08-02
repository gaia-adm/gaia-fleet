#!/bin/bash

# debug with bash -x deploy.sh

# export FLEETCTL_ENDPOINT: docker host IP and 4001 port
if [ -z "$FLEETCTL_ENDPOINT" ]; then
  FLEETCTL_ENDPOINT=http://$(netstat -nr | grep '^0\.0\.0\.0' | awk '{ print $2 }'):4001
  export FLEETCTL_ENDPOINT=${FLEETCTL_ENDPOINT}
fi

# get environment from outside: from CLI argument or env variable - for docker
# run docker on vagrant -e fleetenv=vagrant
fleetenv=$1
if [[ -z "${fleetenv}" ]]; then
  echo Running on AWS by default
else
  echo Running on ${fleetenv}
fi

# check if fleetctl fleet client is mounted into the container
if [[ ! -f /usr/bin/fleetctl ]]; then
  echo "fleetctl is not mounted, mount it with '-v /usr/bin/fleetctl:/usr/bin/fleetctl'"
  exit -1
fi

# helper function
function array_contains_element() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# start fleet unit and wait till 'active' and 'running'
function start_fleet_unit() {
  fleetctl start $1
  # do not wait passive_units to activate
  array_contains_element $1 "${passive_units[@]}"
  if [ $? -eq 0 ]; then
    return 0
  fi
  # wait for ACTIVE status is 'active' or 3 min timeout
  local status=0
  while [ $status -lt 180 ] ;do
    sleep 1
    if [ "$(fleetctl list-units | grep -cw $1)" -ne 0 ]; then
      x=($(fleetctl list-units | grep -w $1 | awk '{print $3}'))
      array_contains_element "active" "${x[@]}"
      if [ $? -eq 0 ]; then
        status=180
      fi
    fi
    status=$((status+1))
 done
}


# submit new/updates fleet units and destroy previous versions, if exist
# return true, if service updated
function load_fleet_unit() {
  local __result=1
  if [[ $(fleetctl list-unit-files | grep -w ${1}) ]]; then
    fleetctl submit ${1} 1&> .tmp
    if cat .tmp | grep -q "differs"; then
      fleetctl destroy ${1}
      fleetctl submit ${1}
      echo "${1} - unit had beed updated"
      __result=0
    else
      echo "${1} - update is not required"
    fi
    rm .tmp
  else
    fleetctl submit ${1}
    echo "${1} - a new unit uploaded"
    __result=0
  fi
  return $__result
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


# deploy = load and start fleet unit, if new unit is loaded or unit is updated
function deploy_fleet_unit() {
  load_fleet_unit $1
  if [ $? -eq 0 ]; then
    start_fleet_unit $1
  fi
}

# core units to be started first
declare -a core_units=( skydns.service registrator.service postgres.vagrant.service cadvisor.service logentries.service vault.service result-upload-service.service )
# all units
declare -a all_units=(*.service)
# timer units
declare -a other_units=( backup-elastic.aws.timer backup-etcd.aws.timer )
# passive units are started by other units or executed only once
declare -a passive_units=( backup-elastic.aws.service backup-etcd.aws.service dex-client-config.service vault-unseal.service )

for u in "${all_units[@]}"; do
  array_contains_element $u "${core_units[@]}"
  if [ $? -eq 0 ]; then
    # for template add two units
    if [[ $u =~ @.service ]]; then
      other_units+=(${u/@.service/@1.service})
      if [[ $(fleetctl list-machines | grep -v MACHINE  | wc -l) -gt 1 ]]; then
        other_units+=(${u/@.service/@2.service})
        if [[ $u =~ es@.service ]]; then
          other_units+=(${u/@.service/@3.service})
        fi
      fi
    else
      other_units+=($u)
    fi
  fi
done


units=( ${core_units[@]} ${other_units[@]} )

for unit in "${units[@]}"; do
  echo "depoyment of: $unit"
  case "$unit" in
    *.vagrant.service )
      if [[ "$fleetenv" = "vagrant" ]]; then
        deploy_fleet_unit $unit
      fi
      ;;
    *.aws.* )
      if [[ "$fleetenv" != "vagrant" ]]; then
        deploy_fleet_unit $unit
      fi
      ;;
    *.service )
      deploy_fleet_unit $unit
      ;;
    *.timer )
      deploy_fleet_unit $unit
      ;;
    * )
      echo not supported file name
      ;;
   esac
done


# cleanup units that do not have corresponding file
cleanup_fleet_units
