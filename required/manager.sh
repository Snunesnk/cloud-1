#!/bin/bash
#ENVFILE="./.env"

##LITTLE FUNCTIONS
function	upcontainers {
	docker compose -f ./docker-compose.yml --env-file $ENVFILE up -d
	echo "Phpmyadmin at https://pma.$DOMAINNAME"
	echo "Wordpress at https://wp.$DOMAINNAME"
}

function	downcontainers {
	docker compose -f ./docker-compose.yml --env-file $ENVFILE down
}

function	restartcontainer {
	downcontainers
	upcontainers
}

function	deletedatas {
	rm -rf ./wordpress-data
	rm -rf ./mariadb-data
}

function	cleancontainers {
	#docker stop $(docker ps -a -q)
	#docker rm $(docker ps -a -q)
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
DOMAINNAME=$DOMAINNAME
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
}

function gethttps {
	sleep 45
	DOMAINNAME=$1
	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
	fi
	mkdir -p nginx/conf/
	cat <<EOF > nginx/conf/default.conf
server {
	listen	80;
	server_name	pma.$1;
	location /.well-known/acme-challenge/ {
		root /var/www/certbot;
	}
	location / {
		return 301 https://pma.$1\$request_uri;
	}
}
server {
	listen	443 ssl;
	http2 on;
	server_name  pma.$1;
	ssl_certificate     /etc/letsencrypt/live/$1/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;
	location ~ /.well-known/acme-challenge/ {
			root /var/www/certbot;
	}
	location / {
			proxy_pass http://phpmyadmin/;
	}
}

server {
	listen       80;
	server_name  wp.$1;
	location /.well-known/acme-challenge/ {
		root /var/www/certbot;
	}
	location / {
		return 301 https://wp.$1\$request_uri;
	}
}
server {
	listen	443 ssl;
	http2 on;
	server_name	wp.$1;
	ssl_certificate	/etc/letsencrypt/live/$1/fullchain.pem;
	ssl_certificate_key	/etc/letsencrypt/live/$1/privkey.pem;
	location ~ /.well-known/acme-challenge {
		allow all;
		root /var/www/certbot;
}
	location / {
		proxy_set_header Connection "";
		proxy_set_header Host \$http_host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_set_header X-Frame-Options SAMEORIGIN;
		proxy_buffers 256 16k;
		proxy_buffer_size 16k;
		fastcgi_param   APPLICATION_ENV  production;
		fastcgi_param   APPLICATION_CONFIG user;
		proxy_pass http://wordpress/;
	}
	location ~ /\.ht {
			deny all;
	}
	location = /favicon.ico { 
			log_not_found off; access_log off; 
	}
	location = /robots.txt { 
			log_not_found off; access_log off; allow all; 
	}
	location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
			expires max;
			log_not_found off;
	}
}
EOF
	docker exec nginx nginx -s reload
	echo "Phpmyadmin at https://pma.$DOMAINNAME"
	echo "Wordpress at https://wp.$DOMAINNAME"
}

function genere_confnginx {
	DOMAINNAME=$1
	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
	fi
	mkdir -p nginx/conf/
	cat <<EOF > nginx/conf/default.conf
server {
	listen	80;
	server_name	pma.$1;
	location /.well-known/acme-challenge/ {
		root /var/www/certbot;
	}
}

server {
	listen       80;
	server_name  wp.$1;
	location /.well-known/acme-challenge/ {
		root /var/www/certbot;
	}
}
EOF
}

function	fcleanservices {
	downcontainers
	deletedatas
	cleancontainers
}

function	deployservices {
	DOMAINNAME=$1
	genereconfigenv $DOMAINNAME
	genere_confnginx $DOMAINNAME

	### creer la structure de document + bons droits
	### mettre les sources
	### ajouter les data wordpress + mariadb
	echo "Et la on rajoute les data wordpress + mariadb maintenant qu'on a mis env et nginx"
}

function	runservices {
	### attention prérequis de deployservices si appel a cette function
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
	apt-get install -y ca-certificates curl gnupg
}

function	installDocker {
	# Uninstall old versions to avoid conflicts
	#for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
	# Add docker gpg key
	if [[ ! -f /etc/apt/keyrings/docker.gpg  ]]
	then
		install -m 0755 -d /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		chmod a+r /etc/apt/keyrings/docker.gpg
	fi
	# Add docker repository
	if [[ ! -f /etc/apt/sources.list.d/docker.list  ]]
	then
		echo \
  			"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  			"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	fi
	# Install docker
	apt-get update
	echo "avant install"
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	# Enable docker + make it start on boot
#	systemctl start docker
	STATUSDOCKER=`systemctl is-active docker`
	if [[ $STATUSDOCKER == "active" ]]
	then
		echo "docker deja active"
		systemctl enable docker
	else
		echo "docker not active"
		systemctl enable docker --now
	fi
echo "avant status"
systemctl status docker
}

function	purgeDocker {
	# Remove packages
	systemctl disable docker --now
	systemctl disable docker.socket --now
	apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	apt-get autoremove -y --purge
	# Remove key for docker
	rm -r /etc/apt/keyrings/docker.gpg
	# Delete all images, containers and volumes
	rm -r /etc/apt/sources.list.d/docker.list
	rm -rf /var/lib/docker
	rm -rf /var/lib/containerd
	rm -rf /var/lib/docker /etc/docker
	#rm /etc/apparmor.d/docker
	groupdel docker
	rm -rf /var/run/docker.sock
}

#deletedatas restartcontainer downcontainers upcontainers
#cleancontainers genereconfigenv genere_confnginx fcleanservices deployservices runservices cleanandrestartservices installDependencies installDocker purgeDocker

