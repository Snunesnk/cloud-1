#!/bin/bash

DOMAINNAME=""
KEEPIMAGES=false

# Loop through the command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keep-images)
            KEEPIMAGES=true
            shift 
            ;;
        *)
            # Assume any other argument is the DOMAIN_NAME
            DOMAINNAME="$1"
            shift
            ;;
    esac
done

if [ -z "$DOMAINNAME" ]; then
    echo "Error: DOMAIN_NAME is required."
    echo "Usage : sudo $0 [--save-images] DOMAIN_NAME"
    exit 1
fi

ENVFILE=".env"
WORKINGDIRECTORY="cloud1-""$DOMAINNAME"

# The script must be launched as root,
# To install everything + start services
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit 1
fi

if [[ ! -d $WORKINGDIRECTORY  ]]
then
	echo "No working directory for $DOMAINNAME"
	exit 1
fi

cd $WORKINGDIRECTORY

# Get utils functions
source ./manager.sh
source ./beautify.sh

fcleanservices $KEEPIMAGES
cd ..
rm -rf $WORKINGDIRECTORY
purgeDocker
