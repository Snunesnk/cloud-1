#!/bin/bash
# Install everything needed to run docker
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
else
	echo "nice"
	exit
fi


# # Enable docker + make it start on boot
# sudo systemctl start docker
# sudo systemctl enable docker


# # Start containers 
# sudo docker-compose up -d
