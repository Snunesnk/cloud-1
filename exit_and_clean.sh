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

if [[ ! -d $WORKINGDIRECTORY  ]]
then
	echo "No working directory for $DOMAINNAME"
	exit
fi
cd $WORKINGDIRECTORY
# Get functions from manager.sh
source ./manager.sh

fcleanservices
cd ..
rm -rf $WORKINGDIRECTORY
purgeDocker
