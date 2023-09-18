#!/bin/bash

INITSWARM=false
DOMAINNAME=""

# The script must be launched as root,
# To install everything + start services
if (( $EUID != 0 )); then
    echo "Please run as root"
    echo "Usage : sudo $0 [--init-swarm|-i] DOMAIN_NAME"
    exit
fi

# Loop through the command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --init-swarm|-i)
            INITSWARM=true
            shift 
            ;;
        *)
            # Assume any other argument is the DOMAIN_NAME
            DOMAINNAME="$1"
            shift
            ;;
    esac
done

# Check if DOMAIN_NAME is empty
if [ -z "$DOMAINNAME" ]; then
    echo "Error: DOMAIN_NAME is required."
    echo "Usage : sudo $0 [--init-swarm|-i] DOMAIN_NAME"
    exit 1
fi

WORKINGDIRECTORY="cloud1-""$DOMAINNAME"
ENVFILE=".env"

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
runservices $INITSWARM
gethttps $DOMAINNAME
