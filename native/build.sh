#!/bin/bash
if [[ "$1" == "ios" || "$1" == "android" ]];
then
    gomobile bind -target "$1" -v .
else
   echo "Incorrect platform specified. Options are: ios, android"
 fi
