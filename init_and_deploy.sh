#!/bin/bash

if [[ $# != 1 ]]; then
        echo "Need 1 parameter, get $# parameters"
        echo "Usage : bash $0 [DOMAIN NAME]"
        exit
fi

DOMAINNAME=$1
ENVFILE=".env"
WORKINGDIRECTORY="cloud1-""$DOMAINNAME"

# Install everything needed to run docker
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi




function	genereconfigenv {
    cd 
	touch $ENVFILE
	cat <<EOF > $ENVFILE
MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=db
MYSQL_USER=user
MYSQL_PASSWORD=password
EOF
}


# # Enable docker + make it start on boot
# sudo systemctl start docker
# sudo systemctl enable docker


# # Start containers 
# sudo docker-compose up -d

#create and move to working repertory 
mkdir -p $WORKINGDIRECTORY
cd $WORKINGDIRECTORY
genereconfigenv

