#!/bin/bash

for i in $(seq 2 `docker images | wc -l`);do
docker save $(docker images | sed -n "`echo $i`p" | awk '{print$1":"$2}') > $(echo $(docker images | sed -n "`echo $i`p" | awk '{print$1":"$2}' | sed 's/:/_/g' | sed 's/\//_/g' | sed 's/\./_/g')".tar");done
