#!/usr/bin/sh

CURRENT_BRANCH=$(git branch --show-current)

if [[ $CURRENT_BRANCH != 'main' ]]; then
  echo "Error: Cannot deploy from branch '$CURRENT_BRANCH'.  Can ONLY deploy from 'main'."
  exit 1
fi

echo 'Deploying to Github Pages.........'
echo ''
echo ''

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

echo "Deploying recent commits from branch 'main' to subtree branch 'gh-pages'...."
# Push the contents of the ./dist folder to the gh-pages branch for deployment
git subtree push --prefix dist origin gh-pages
echo ''
