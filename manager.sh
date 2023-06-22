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
	rm -rf ~/data/wordpress/*
	rm -rf ~/data/mariadb/*
}

function	cleancontainers {
	docker system prune --all --force --volumes
	docker network prune --force
	docker volume prune --force
}

##MAIN FUNCTIONS
# function	genereconfigenv {
#     cd 
# 	touch $1
# 	cat <<EOF > $1
# MYSQL_ROOT_PASSWORD=root_password
# MYSQL_DATABASE=db
# MYSQL_USER=user
# MYSQL_PASSWORD=password
# EOF
# }

function	genereconfigenv {
	MYSQL_ROOT_PASSWORD="root_password-$1"
	MYSQL_DATABASE="db-$1"
	MYSQL_USER="user-$1"
	MYSQL_PASSWORD="password-$1"
	cat <<EOF > .env
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
}

function	fcleanservices {
	downcontainers
	cleancontainers
	deletedatas
}

function	deployservices {
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
