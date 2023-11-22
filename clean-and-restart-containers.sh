#!/bin/bash
# The script must be launched as root,
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
DOMAINNAME=""
KEEPIMAGES=false
if [[ $# < 1 || $# > 2  ]]; then
        echo "Need 1 or 2 parameter, get $# parameters"
        echo "Usage : sudo bash [--keep-images] $0 [DOMAIN NAME]"
        exit
fi

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
    echo "Usage : sudo bash $0 [--keep-images] DOMAIN_NAME"
    exit 1
fi

ENVFILE=".env"
WORKINGDIRECTORY="cloud1-""$DOMAINNAME"

if ! [[ -d $WORKINGDIRECTORY  ]]
then
	echo "You didn't already deploy  $DOMAINNAME"
	echo "Please use the init script"
	exit
fi
cd $WORKINGDIRECTORY

# Get utils functions
source ./manager.sh
source ./beautify.sh

fcleanservices $KEEPIMAGES
getRateLimit
deployservices $DOMAINNAME
gethttp $DOMAINNAME
runservices
gethttps $DOMAINNAME
print_info "Deployment done."
print_info "Phpmyadmin at https://pma.$DOMAINNAME"
print_info "Wordpress at https://wp.$DOMAINNAME - Hint : admin / Adminhijk67"
print_info "Database connexion infos into .env file"
