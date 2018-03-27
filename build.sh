#!/bin/bash
xcodebuild
sudo mv build/Release/zira /usr/local/bin/
rm -rf ./build
