#!/bin/bash
ENVFILE="./.env"

##LITTLE FUNCTIONS
function	upcontainers {
	docker compose -f ./docker-compose.yml --env-file $ENVFILE up -d
}

function	downcontainers {
	docker compose -f ./docker-compose.yml --env-file $ENVFILE down
}

function	restartcontainer {
	downcontainers
	upcontainers
}

function	deletedatas {
	rm -rf ~/wordpress-data
	rm -rf ~/mariadb-data
}

function	cleancontainers {
	docker stop $(docker ps -a -q)
	docker rm $(docker ps -a -q)
	docker system prune --all --force --volumes
}

##MAIN FUNCTIONS

function	genereconfigenv {
	DOMAINNAME=$1
	RANDOM=$(date +%s%N | cut -b10-19)
	MYSQL_ROOT_PASSWORD="root_password-$RANDOM"
	MYSQL_DATABASE="db-$RANDOM"
	MYSQL_USER="user-$RANDOM"
	MYSQL_PASSWORD="password-$RANDOM"
	cat <<EOF > .env
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
}

function genere_confnginx {
	DOMAINNAME=$1
	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
	fi
	mkdir -p nginx
	cd nginx
	cat <<EOF > default.conf
server {
    listen       80;
    server_name  pma.$1;
    location / {
        proxy_pass http://phpmyadmin/;
    }
}
server {
    listen       80;
    server_name  wp.$1;

    location / {
        fastcgi_param   APPLICATION_ENV  production;
        fastcgi_param   APPLICATION_CONFIG user;
        proxy_pass http://wordpress/;
    }
}
EOF
 cd ..
}

function	fcleanservices {
	downcontainers
	deletedatas
	cleancontainers
}

function	deployservices {
	DOMAINNAME=$1
	genere_confnginx $DOMAINNAME

	### creer la structure de document + bons droits
	### mettre les sources
	### ajouter les data wordpress + mariadb
	echo "TODO"
}

function	runservices {
	### attention prérequis de deployservices si appel a cette function
	### donner les permission chmod +x docker compose
	upcontainers
}

function	cleanandrestartservices {
	fcleancontainers
	deployservices
	runservices
}



##function install instance :
function	installDependencies {
	apt-get update
	apt-get install -y apt-transport-https wget software-properties-common make python3
	# Docker dependencies
	apt-get install ca-certificates curl gnupg
}

function	installDocker {
	# Uninstall old versions to avoid conflicts
	for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
	apt-get update
	# Add docker gpg key
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	chmod a+r /etc/apt/keyrings/docker.gpg
	# Add docker repository
	echo \
  		"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  		"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	# Install docker
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	# Enable docker + make it start on boot
	systemctl start docker
	systemctl enable docker
}

function	purgeDocker {
	downcontainers
	cleancontainers
	# Remove packages
	apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
	# Delete all images, containers and volumes
	sudo rm -rf /var/lib/docker
	sudo rm -rf /var/lib/containerd
}



#deletedatas restartcontainer downcontainers upcontainers
#cleancontainers genereconfigenv genere_confnginx fcleanservices deployservices runservices cleanandrestartservices installDependencies installDocker purgeDocker

