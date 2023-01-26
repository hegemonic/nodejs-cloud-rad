#!/bin/bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create files to be uploaded to devsite. 
# When running locally, run `docfx --serve` in ./yaml/ after this script


echo "mkdir -p ./etc"
mkdir -p ./etc

echo "cp $(npm root)/@google-cloud/cloud-rad/api-extractor.json ."
cp "$(npm root)/@google-cloud/cloud-rad/api-extractor.json" .
echo "npx @microsoft/api-extractor run --local"
npx @microsoft/api-extractor run --local

# copy the common.api.json file as it is used as a base class
# If cloud-rad is running for common, the copied file will be overwritten by api-extractor
echo "cp $(npm root)/@google-cloud/cloud-rad/api-extractor-configs/common.api.json temp"
cp "$(npm root)/@google-cloud/cloud-rad/api-extractor-configs/common.api.json" temp
echo "cp $(npm root)/@google-cloud/cloud-rad/api-extractor-configs/google-auth-library.api.json temp"
cp "$(npm root)/@google-cloud/cloud-rad/api-extractor-configs/google-auth-library.api.json" temp

echo "node $(npm root)/@googleapis/api-documenter/bin/api-documenter yaml --input-folder=temp"
node "$(npm root)/@googleapis/api-documenter/bin/api-documenter" yaml --input-folder=temp

# replace markdown code examples with html, see b/204924531
echo "node $(npm root)/@google-cloud/cloud-rad/prettyPrint.js"
node "$(npm root)/@google-cloud/cloud-rad/prettyPrint.js"

# remove common and auth from toc
# echo "node $(npm root)/@google-cloud/cloud-rad/deleteBaseClasses.js"
# node "$(npm root)/@google-cloud/cloud-rad/deleteBaseClasses.js"
echo "node $(npm root)/@google-cloud/cloud-rad/generate-devsite-stub.mjs"
node "$(npm root)/@google-cloud/cloud-rad/generate-devsite-stub.mjs"

# remove interfaces from toc
echo "node $(npm root)/@google-cloud/cloud-rad/removeInterface.js"
node "$(npm root)/@google-cloud/cloud-rad/removeInterface.js"

# remove protos from toc
echo "node $(npm root)/@google-cloud/cloud-rad/removeProtos.js"
node "$(npm root)/@google-cloud/cloud-rad/removeProtos.js"

# Clean up TOC
# Delete SharePoint item, see https://github.com/microsoft/rushstack/issues/1229
sed -i -e '1,3d' ./yaml/toc.yml
# Shift everything to the left
sed -i -e 's/^    //' ./yaml/toc.yml

# Add "items:" to short toc for overview file
if [[ $(wc -l <./yaml/toc.yml) -le 3 ]] ; then
  sed -i -e '3a\
 \ \ \ items:
' ./yaml/toc.yml
fi

# Add Quickstart section, same as README
sed -i -e '4a\
 \ \ \ \ \ - name: Quickstart
' ./yaml/toc.yml
sed -i -e '5a\
 \ \ \ \ \ \ \ homepage: index.md
' ./yaml/toc.yml


# Add package overview section
sed -i -e '6a\
 \ \ \ \ \ - name: Overview
' ./yaml/toc.yml
sed -i -e '7a\
 \ \ \ \ \ \ \ homepage: overview.html
' ./yaml/toc.yml


# We add common.api.json abd google-auth-library.api.json to temp for base class references.
# When generating the docs for nodejs-common or auth itself, there will only 
# be two files in temp. Otherwise, delete common.api.json and auth.
numberOfFiles=$(ls temp | wc -l)
if [[ $numberOfFiles -ge 3 ]]; then
  echo "rm temp/common.api.json"
  rm temp/common.api.json
  rm temp/google-auth-library.api.json
fi

# add href for external classes, see b/195674809
echo "node $(npm root)/@google-cloud/cloud-rad/removeProtos.js"
node "$(npm root)/@google-cloud/cloud-rad/addLinks.js"

NAME=$(ls temp | sed s/.api.json*//)
## Copy everything to devsite
echo "mkdir -p ./_devsite"
mkdir -p ./_devsite
echo "mkdir -p ./_devsite/$NAME"
mkdir -p ./_devsite/$NAME

echo "cp ./yaml/$NAME/* ./_devsite/$NAME || :"
cp ./yaml/$NAME/* ./_devsite/$NAME || :
echo "cp ./yaml/toc.yml ./_devsite/toc.yml"
cp ./yaml/toc.yml ./_devsite/toc.yml

## Rename the default overview page,
echo "mv ./yaml/$NAME.yml ./_devsite/overview.yml"
mv ./yaml/$NAME.yml ./_devsite/overview.yml

## readme is not allowed as filename
echo "cp ./README.md ./_devsite/index.md"
cp ./README.md ./_devsite/index.md
