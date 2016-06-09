#!/bin/bash
if [[ "$1" == "ios" || "$1" == "android" ]];
then
    gomobile bind -target "$1" -v .

    if [[ "$1" == "ios" ]];
    then
      rm -rf ../example/ios/ios-sc-demo/SocketClusterClient.framework
      mv SocketClusterClient.framework ../example/ios/ios-sc-demo/
    fi

else
   echo "Incorrect platform specified. Options are: ios, android"
 fi
