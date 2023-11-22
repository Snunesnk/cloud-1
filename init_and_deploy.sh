#!/bin/bash
# The script must be launched as root,
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
DOMAINNAME=""

if [[ $# != 1 ]]; then
        echo "Need 1 parameter, get $# parameters"
        echo "Usage : sudo $0 [DOMAIN NAME]"
        exit
fi

DOMAINNAME=$1
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

# Get utils functions
source ./manager.sh
source ./beautify.sh

installDependencies
installDocker
getRateLimit
deployservices $DOMAINNAME
gethttp $DOMAINNAME
runservices
gethttps $DOMAINNAME
print_info "Deployment done."
print_info "Phpmyadmin at https://pma.$DOMAINNAME"
print_info "Wordpress at https://wp.$DOMAINNAME - Hint : admin / Adminhijk67"
print_info "Database connexion infos into .env file"
