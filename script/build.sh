#!/bin/bash

# Update to latest compatible quicktype release
npm upgrade quicktype

# Bundle quicktype
browserify \
    node_modules/quicktype/dist/index.js \
    -s quicktype \
    -o quicktype-xcode/quicktype.js

# Sync Xcode plugin version with quicktype
VERSION=`npm -j ls quicktype | jq -r .dependencies.quicktype.version`
agvtool new-marketing-version $VERSION
agvtool new-version -all $VERSION