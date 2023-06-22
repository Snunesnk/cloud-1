#!/bin/bash

if [[ $# != 1 ]]; then
        echo "Need 1 parameter, get $# parameters"
        echo "Usage : sudo $0 [DOMAIN NAME]"
        exit
fi

DOMAINNAME=$1
ENVFILE=".env"
WORKINGDIRECTORY="cloud1-""$DOMAINNAME"

# The script must be launched as root,
# To install everything + start services
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

# Get functions from manager.sh
source ./manager.sh

#create and move to working repertory 
mkdir -p $WORKINGDIRECTORY
cd $WORKINGDIRECTORY
genereconfigenv $DOMAINNAME
installDependencies
installDocker
runservices


