#!/usr/bin/sh

# Load and check environment variables
if [[ ! -f .env ]]; then
  echo 'ERROR: No .env file found with the required environment variables.'
  echo ''
  exit 1
fi
source ./.env

# DOMAIN is the domain name External to Github Pages
if [[ ! $DOMAIN ]]; then
  echo 'ERROR: Environment variable DOMAIN not set.  Please set it in the .env file.'
  echo ''
  exit 1
fi

# Check if on current branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ $CURRENT_BRANCH != 'main' ]]; then
  echo "Error: Cannot deploy from branch '$CURRENT_BRANCH'.  Can ONLY deploy recent commits from 'main'."
  exit 1
fi

# Start the Deployment
echo 'Deploying to Github Pages.........'
echo ''

# Recreate CNAME file based on the environment variable DOMAIN
echo "Regenerating CNAME file for '$DOMAIN'."
echo ''
echo $DOMAIN > ./dist/CNAME

# Check for the LICENSE file and copy it if it doesn't exist, else just copy it.
if [[ -f ./dist/LICENSE ]]; then
  echo 'LICENSE file found in deployment folder, ./dist.  Overwritting...'
  rm ./dist/LICENSE
  cp LICENSE ./dist/LICENSE
else
  echo 'No LICENSE file found in deployment folder, ./dist.  Copying...'
  cp LICENSE ./dist/LICENSE
fi
echo ''

# Just in case there are issues with pushing to gh-pages using options '-f' or '--force' will delete and recreate it
if [[ $1 == '-f' || $1 == '--force' ]]; then
  echo "Deleting and recreating branch 'gh-pages'..."
  echo ''
  git push origin --delete gh-pages
fi

# Push the contents of the ./dist folder to the gh-pages branch for deployment
echo "Deploying recent commits from branch 'main' to subtree branch 'gh-pages'...."
git subtree push --prefix dist origin gh-pages
echo ''
