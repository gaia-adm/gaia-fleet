#!/bin/bash

flag=$1
if [[ ! -z ${flag} ]]; then 
  if [[ ${flag} == "--help" ]]; then
    echo This script stops and destroys all unit and unit-files deployed in the system
    echo Running this script with --volume flag removes also rexray volumes created for some services
    exit 0
  elif [[ ${flag} == "--volume" ]]; then
    echo Volumes removal included...
  fi;
fi;

for unit in $(fleetctl list-units -fields unit -no-legend); do
 fleetctl stop $unit 
 fleetctl destroy $unit
done

for file in $(fleetctl list-unit-files -fields unit -no-legend); do
 fleetctl stop $file 
 fleetctl destroy $file
done

if [[ ${flag} == "--volume" ]]; then
  sudo rm -rf /var/lib/rexray/volumes/*
fi;

