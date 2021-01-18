#!/usr/bin/env sh

# Check for dependency jq
#   NOTE: Refer to jq cookbook for usage: https://github.com/stedolan/jq/wiki/Cookbook
if [[ ! $(which jq) ]]; then
  echo 'ERROR: Missing JSON query tool "jq".  Please install it.'
  echo '       Depending on your system, any of the following commands:'
  echo '       - For Mac using Homebrew: `brew install jq`'
  echo '       - For Debian Linux using APT (with admin privilages): `apt install -y jq`'
  echo '       - For Windows using Chocolatey (with admin privilages): `choco install -y jq`' # TODO: Test this command
  echo ''
  exit 1
fi

# Load and check environment variables
if [[ ! -f .env ]]; then
  echo 'ERROR: No .env file found with the GoDaddy credentials and other required environment variables.'
  echo ''
  exit 1
fi
source ./.env

# GODADDY_KEY is the GoDaddy API key
if [[ ! $GODADDY_KEY ]]; then
  echo 'ERROR: Environment variable GODADDY_KEY not set.  Please set it in the .env file.'
  echo ''
  exit 1
fi
# GODADDY_SECRET is the GoDaddy API secret
if [[ ! $GODADDY_SECRET ]]; then
  echo 'ERROR: Environment variable GODADDY_SECRET not set.  Please set it in the .env file.'
  echo ''
  exit 1
fi
# A_RECORD_IPS is a Shell array of IPS to update the domain's A records
if [[ ! $A_RECORD_IPS ]]; then
  echo 'ERROR: Environment variable A_RECORD_IPS not set.  Please set it in the .env file as a shell script array.'
  echo ''
  exit 1
fi
# DOMAIN is the domain name managed by Godaddy
if [[ ! $DOMAIN ]]; then
  echo 'ERROR: Environment variable DOMAIN not set.  Please set it in the .env file.'
  echo ''
  exit 1
fi
# CNAME is the other domain you want the Godaddy domain name to point to
if [[ ! $CNAME ]]; then
  echo 'ERROR: Environment variable CNAME not set.  Please set it in the .env file.'
  echo ''
  exit 1
fi

# ----------------------------------------------------------------------------------------------------------
# Define some functions
# Documentation on GoDaddy API can be found here: https://developer.godaddy.com/doc/
# ----------------------------------------------------------------------------------------------------------
# Utility function that joins the arguments as delimiter seperated text
# The first argument is the delimiter, the rest are the items to be joined
function join {
  local delimiter=$1
  shift
  local items_to_be_joined=$1
  shift
  printf %s "$items_to_be_joined" "${@/#/$delimiter}";
}

# Check the status of the domain
function check_if_you_own_the_domain_and_is_active {
  curl --silent -X GET \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    "https://api.godaddy.com/v1/domains?statuses=ACTIVE" \
    | jq ".[] | select(.domain | . == \"$1\")"
}

# Get the existing A records
function get_domain_A_records {
  curl --silent -X GET \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    "https://api.godaddy.com/v1/domains/$1/records/A/@" \
    | jq '.[] | select(.name | . == "@")'
}

# Replace the existing A records
function set_domain_A_records {
  local A_RECORDS=()
  for IP in ${@:2}; do
    A_RECORDS+=("{\"ttl\": 600, \"data\": \"$IP\", \"protocol\": \"https\"}")
  done
  local DATA="[ $(join ', ' "${A_RECORDS[@]}") ]"

  curl --silent -X PUT \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    -H 'Content-Type: application/json' \
    "https://api.godaddy.com/v1/domains/$1/records/A/@" \
    -d "$DATA" \
    | jq .
}

# Get the existing CNAME records
function get_domain_CNAME_records {
  curl --silent -X GET \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    "https://api.godaddy.com/v1/domains/$1/records/CNAME/www" \
    | jq '.[] | select(.name | . == "www")'
}

# Replace the existing CNAME records
function set_domain_CNAME_records {
  curl --silent -X PUT \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    -H 'Content-Type: application/json' \
    "https://api.godaddy.com/v1/domains/$1/records/CNAME/www" \
    -d "[{\"ttl\": 600, \"data\": \"$2\", \"protocol\": \"https\"}]" \
    | jq .
}

# ----------------------------------------------------------------------------------------------------------
# Do the actual work here
# ----------------------------------------------------------------------------------------------------------
echo "Checking if domain '$DOMAIN' is yours and is active..."
if [[ ! $(check_if_you_own_the_domain_and_is_active $DOMAIN) ]]; then
  echo "ERROR: Domain '$DOMAIN' does not appear to be active and/or not owned by you."
  exit 1
else
  echo "Great!  You own domain '$DOMAIN' and it's active."
fi
echo ''

echo "Checking existing A record for '$DOMAIN' to point to $(join ', ' "${A_RECORD_IPS[@]}")."
EXISING_A_RESULT="$(get_domain_A_records $DOMAIN)"
if [[ $EXISING_A_RESULT ]]; then
  echo "Existing A record found for domain '$DOMAIN'.  Will be replacing it."
  echo "$EXISING_A_RESULT"
else
  echo "No existing A record found for domain '$DOMAIN'.  Will be adding it."
fi
echo ''

echo "Updating A record for '$DOMAIN' to point to $(join ', ' "${A_RECORD_IPS[@]}")."
set_domain_A_records $DOMAIN "${A_RECORD_IPS[@]}"
echo "$(get_domain_A_records $DOMAIN)"

echo "Checking existing CNAME record for 'www.$DOMAIN' to point to '$CNAME'."
EXISING_CNAME_RESULT="$(get_domain_CNAME_records $DOMAIN)"
if [[ $EXISING_CNAME_RESULT ]]; then
  echo "Existing CNAME record found for domain 'www.$DOMAIN'.  Will be replacing it."
  echo "$EXISING_CNAME_RESULT"
else
  echo "No existing CNAME record found for domain 'www.$DOMAIN'.  Will be adding it."
fi
echo ''

echo "Updating CNAME record for 'www.$DOMAIN' to point to '$CNAME'."
set_domain_CNAME_records $DOMAIN $CNAME
echo "$(get_domain_CNAME_records $DOMAIN)"
