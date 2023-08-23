#!/bin/bash

if [[ $# != 1 ]]; then
        echo "Need 1 parameter, get $# parameters"
        echo "Usage : sudo $0 [DOMAIN NAME]"
        exit
fi

DOMAINNAME=$1
WORKINGDIRECTORY="cloud1-""$DOMAINNAME"
ENVFILE=".env"

# The script must be launched as root,
# To install everything + start services
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
if [[ -d $WORKINGDIRECTORY  ]]
then
	echo "The working directory is already here for $DOMAINNAME"
	echo "Not deploying again"
	exit
fi

## Create required copy and move in
cp -r required $WORKINGDIRECTORY
cd $WORKINGDIRECTORY

# Get functions from manager.sh
source ./manager.sh

#create and move to working repertory
installDependencies
installDocker
deployservices $DOMAINNAME
runservices
gethttps $DOMAINNAME
