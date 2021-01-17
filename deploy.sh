#!/usr/bin/sh

# Check for the LICENSE file and copy it if it doesn't exist, else just copy it.
if [[ -f ./dist/LICENSE ]]; then
  echo 'LICENSE file found in deployment folder, ./dist.  Overwritting...'
  rm ./dist/LICENSE
  cp LICENSE ./dist/LICENSE
else
  echo 'No LICENSE file found in deployment folder, ./dist.  Copying...'
  cp LICENSE ./dist/LICENSE
fi

# Push the contents of the ./dist folder to the gh-pages branch for deployment
git subtree push --prefix dist origin gh-pages
