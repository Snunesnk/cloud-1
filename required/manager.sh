#!/bin/bash
#ENVFILE="./.env"

# Function to initialize Docker swarm
init_swarm() {
    print_action "docker swarm init --advertise-addr $(hostname -i)" "Start new swarm"
}

# Function to monitor for new nodes
monitor_nodes() {
    while true; do
        # Check for new nodes
        new_nodes=$(docker node ls --format "{{.Hostname}}")
        
        if [ -n "$new_nodes" ]; then
            print_info "Current nodes in the swarm:"
			echo "$new_nodes"
            read -p "Scan for new nodes? (y/n): " choice
            if [ "$choice" = "n" ]; then
                print_info "Proceeding with current nodes."
                break
            fi
        fi
    done
}

wait_for_container() {
	max_retries=10
	retry_count=0

	name=$1

	while [ -z "$(sudo docker ps --filter name=$name --filter status=running | grep 'Up')" ]; do
    	if [ $retry_count -ge $max_retries ]; then
        	echo "Maximum retries reached. Exiting."
        	exit 1
    	fi

		print_info "Waiting for $name container to start... Retry $retry_count/$max_retries"

    	retry_count=$((retry_count + 1))
    	sleep 10
	done
}

##LITTLE FUNCTIONS
function	upcontainers {
	init_swarm
	STACKNAME="cloud-1"

	# If INITSWARM is true, initialize Docker swarm
	if [ "$1" = true ]; then
		monitor_nodes

		num_nodes=$(docker node ls --format "{{.ID}}" | wc -l)
		print_action "env $(cat $ENVFILE | grep ^[A-Z] | xargs) docker stack deploy --compose-file docker-compose.yml --with-registry-auth $STACKNAME" "Start services"
		print_action "docker service scale '$STACKNAME'_wordpress=$num_nodes" "Scale wordpress"
		print_action "docker service scale '$STACKNAME'_mariadb=$num_nodes" "Scale mariadb"
	else
		# print_action "env $(cat $ENVFILE | grep ^[A-Z] | xargs) docker stack deploy --compose-file docker-compose.yml $STACKNAME" "Start services"
		print_action "" "Start services"
		env $(cat $ENVFILE | grep ^[A-Z] | xargs) docker stack deploy --compose-file docker-compose.yml --with-registry-auth $STACKNAME
	fi

	print_action "wait_for_container nginx" "Wait for nginx to boot"
	print_action "wait_for_container wordpress" "Wait for wordpress to boot"
	print_action "wait_for_container phpmyadmin" "Wait for phpmyadmin to boot"
	print_action "wait_for_container mariadb" "Wait for mariadb to boot"
}

function	downcontainers {
	print_action "docker compose -f ./docker-compose.yml down" "Down all containers"
}

function	restartcontainer {
	downcontainers
	upcontainers
}

function	deletedatas {
	print_action "rm -rf ./wordpress-data" "Remove wordpress-data folder"
	print_action "rm -rf ./mariadb-data" "Remove mariadb-data folder"
}

function	cleancontainers {
	print_action "docker swarm leave --force" "Leave swarm"

	if [[ $1 == true ]]
	then

		print_action "docker volume prune --force" "Remove volumes"
		print_action "docker network prune --force" "Remove networks"
	else
		print_action "docker system prune --all --force --volumes" "Remove containers, volumes, networks and images"
		print_action "docker builder prune --all --force" "Remove docker build cache"
	fi
}

##MAIN FUNCTIONS

function	genereconfigenv {
	DOMAINNAME=$1
	RANDOM=$(date +%s%N | cut -b10-19)
	MYSQL_ROOT_PASSWORD="root_password-$RANDOM"
	MYSQL_DATABASE="db-$RANDOM"
	MYSQL_USER="user-$RANDOM"
	MYSQL_PASSWORD="password-$RANDOM"

	print_action "" "Generate .env"
	echo "DOMAINNAME=$DOMAINNAME" > .env
	echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env
	echo "MYSQL_DATABASE=$MYSQL_DATABASE" >> .env
	echo "MYSQL_USER=$MYSQL_USER" >> .env
	echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
}

function gethttps {
	DOMAINNAME=$1
	INITSWARM=$2

	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
		print_info "No domain name provided, setting it to 'localhost'"
	fi

	print_header "Get letsencrypt certificates"
	print_action "certbot certonly --cert-name ${DOMAINNAME} --webroot --webroot-path ./certbot-data --config-dir ./letsencrypt --email maiiwen@42l.fr --agree-tos --no-eff-email -d wp.${DOMAINNAME} -d pma.${DOMAINNAME} --test-cert --break-my-certs --force-renewal" "Asking for new certificate"

	print_header "Generate HTTPS nginx configuration"
	print_action "" "Fill nginx configuration file"
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
			proxy_set_header X-Forwarded-Proto https;
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
			root /var/www/html;
			expires max;
			log_not_found off;
	}
}
EOF

	print_action "docker exec $(docker ps -q -f name=nginx) nginx -s reload" "Update nginx configuration"
	print_action "wait_for_container nginx" "Wait for nginx to reload"
	
}

function gethttp {
	print_header "Generate HTTP nginx configuration"

	DOMAINNAME=$1
	INITSWARM=$2
	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
		print_info "No domain name provided, setting it to 'localhost'"
	fi

	print_action "mkdir -p nginx/conf/" "Create nginx directory"
	print_action "" "Fill nginx configuration file"
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
	listen       80;
	server_name  wp.$1;
	location /.well-known/acme-challenge/ {
		root /var/www/certbot;
	}
	location / {
		return 301 https://wp.$1\$request_uri;
	}
}

EOF
}

function genere_confnginx {
	DOMAINNAME=$1
	if [[ $DOMAINNAME == '' ]]
	then
		DOMAINNAME="localhost"
		print_info "No domain name provided, setting it to 'localhost'"
	fi

	print_action "mkdir -p nginx/conf/" "Create nginx configuration folder"
	print_action "echo 'no action'" "Create nginx configuration file"
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
	print_header "Cleaning services"
	downcontainers
	deletedatas
	cleancontainers $1
}

function	deployservices {
	print_header "Generating configuration files"

	DOMAINNAME=$1
	genereconfigenv $DOMAINNAME
	genere_confnginx $DOMAINNAME
}

function	runservices {
	### attention prérequis de deployservices si appel a cette function
	print_header "Launching services"
	upcontainers $1
}

function	cleanandrestartservices {
	fcleancontainers
	deployservices
	runservices
}

# List of dependencies
dependencies=(
 "apt-transport-https"
 "wget"
 "software-properties-common"
 "make"
 "python3"
 "ca-certificates" 
 "curl"
 "gnupg"
 "jq"
 "certbot"
 )


##function install instance :
function	installDependencies {
	print_header "Installing dependencies"
	print_action "apt-get update" "Update"

	# Check and install dependencies
	for dep in "${dependencies[@]}"; do
		print_action "apt-get install -y $dep" "Install $dep"
	done
}

function	installDocker {
	print_header "Installing docker"

	# Add docker gpg key
	if [[ ! -f /etc/apt/keyrings/docker.gpg  ]]
	then
		print_action "install -m 0755 -d /etc/apt/keyrings" "Create folder for docker gpg key"
		print_action "" "Download gpg key"
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		print_action "chmod a+r /etc/apt/keyrings/docker.gpg" "Set key permissions"
	fi
	# Add docker repository
	if [[ ! -f /etc/apt/sources.list.d/docker.list  ]]
	then
		print_action '' "Add docker repository"
		echo \
  			"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  			"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	fi

	# Install docker
	print_action "apt-get update" "Update"
	print_action "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Install docker"

	# Enable docker + make it start on boot
	STATUSDOCKER=`systemctl is-active docker`
	if [[ $STATUSDOCKER == "active" ]]
	then
		print_action "systemctl enable docker" "Restart docker"
	else
		print_action "systemctl enable docker --now" "Enable docker"
	fi
}

function	purgeDocker {
	print_header "Remove docker"

	# Remove packages
	print_action "systemctl disable docker --now" "Disable docker"
	print_action "systemctl disable docker.socket --now" "Disable docker socket"
	print_action "apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "Remove all docker binaries"
	print_action "apt-get autoremove -y --purge" "Remove dependencies"
	# Remove key for docker
	print_action "rm -r /etc/apt/keyrings/docker.gpg" "Remove docker key"
	# Delete all images, containers and volumes
	print_action "rm -r /etc/apt/sources.list.d/docker.list" "Remove content of /etc/apt/sources.list.d/docker.list"
	print_action "rm -rf /var/lib/docker" "Remove content of /var/lib/docker"
	print_action "rm -rf /var/lib/containerd" "Remove content of /var/lib/containerd"
	print_action "rm -rf /var/lib/docker" "Remove content of /var/lib/docker"
	print_action "rm -rf /etc/docker" "Remove content of /etc/docker"
	#rm /etc/apparmor.d/docker
	print_action "groupdel docker" "Remove docker group"
	print_action "rm -rf /var/run/docker.sock" "remove docker daemon"
}

getRateLimit() {
	IMAGE="ratelimitpreview/test"
	TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$IMAGE:pull" | jq -r .token)
	http_response=$(curl -s --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/$IMAGE/manifests/latest)
	ratelimit_remaining=$(echo "$http_response" | grep -i 'ratelimit-remaining:' | awk -F '[:;]' '{print $2}' | tr -d ' ')
	print_info "Remainig docker pulls: $ratelimit_remaining"

	if [[ $ratelimit_remaining == "0" ]]
	then
		print_info "/!\\ No more pull allowed. Impossible to start services. Try later, or upgrade pull rate limit."
		exit 1
	fi
}

#deletedatas restartcontainer downcontainers upcontainers
#cleancontainers genereconfigenv genere_confnginx fcleanservices deployservices runservices cleanandrestartservices installDependencies installDocker purgeDocker

