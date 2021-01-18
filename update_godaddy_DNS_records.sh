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
  echo 'ERROR: No .env file found with the GoDaddy credentials.'
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
# DOMAIN is the domain name manages by Godaddy
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
# Check the status of the domain
function check_if_you_own_the_domain_and_is_active {
  curl --silent -X GET \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    "https://api.godaddy.com/v1/domains?statuses=ACTIVE" \
    | jq ".[] | select(.domain | . == \"$1\")"
}

# Get the existing CNAME records
function get_domain_CNAME_details {
  curl --silent -X GET \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    "https://api.godaddy.com/v1/domains/$1/records/CNAME/www" \
    | jq '.[] | select(.name | . == "www")'
}

# Replace the existing CNAME records
function set_domain_CNAME {
  curl --silent -X PUT \
    -H "Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET" \
    -H 'Content-Type: application/json' \
    "https://api.godaddy.com/v1/domains/$1/records/CNAME/www" \
    -d "[{\"ttl\": 600, \"data\": \"$2\"}]" \
    | jq .
}

# ----------------------------------------------------------------------------------------------------------
# Do the actual work here
# ----------------------------------------------------------------------------------------------------------

echo $IPS

exit 0

echo "Checking if domain '$DOMAIN' is yours and is active..."
if [[ ! $(check_if_you_own_the_domain_and_is_active $DOMAIN) ]]; then
  echo "ERROR: Domain '$DOMAIN' does not appear to be active and/or not owned by you."
  exit 1
else
  echo "Great!  You own domain '$DOMAIN' and it's active."
fi
echo ''

echo "Checking existing CNAME record for '$DOMAIN' to point to '$CNAME'."
EXISING_CNAME_RESULT="$(get_domain_CNAME_details $DOMAIN)"
if [[ $EXISING_CNAME_RESULT ]]; then
  echo "Existing CNAME record found for domain '$DOMAIN'.  Will be replacing it."
  echo "$EXISING_CNAME_RESULT"
else
  echo "No existing CNAME record found for domain '$DOMAIN'.  Will be adding to it."
fi
echo ''

echo "Updating CNAME record for '$DOMAIN' to point to '$CNAME'."
set_domain_CNAME $DOMAIN $CNAME
echo "$(get_domain_CNAME_details $DOMAIN)"
