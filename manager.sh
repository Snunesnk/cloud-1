#!/bin/bash
ENVFILE="./.env"

##LITTLE FUNCTIONS
function	upcontainers {
	docker-compose -f ./docker-compose.yml --env-file $ENVFILE up -d
}

function	downcontainers {
	docker-compose -f ./docker-compose.yml --env-file $ENVFILE down
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
function	fcleanservices {
	downcontainers
	cleancontainers
	deletedatas
}

function	deployservices {
	### creer la structure de document + bons droits
	### mettre les sources
	### ajouter les data wordpress + mariadb
}

function	runservices {
	### attention prérequis de deployservices si appel a cette function
	### donner les permission chmod +x docker-compose
	upcontainers
}

function	cleanandrestartservices {
	fcleancontainers
	deployservices
	runservices
}



##function install instance :
# installer dependances : apt-transport-https, ca-certificates, curl, wget, gnupg-agent, software-properties-common, make, python3
# intaler docker (installer gpg key + mettre dans apt et install docker-ce OU install docker.io) + install docker-compose

