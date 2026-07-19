#!/bin/bash

PORT=5000
CONTAINER_NAME="registry"
printf "Checking if registry image exists or not\n"
existing_images=$(docker image list --format '{{.Repository}}')

if echo $existing_images | grep -i "registry" > /dev/null; then
  printf "Image already exists! Skipping pulling action\n"
else
  printf "Pulling image of registry\n"
  docker pull registry:3
fi

printf "Starting up the registry image in localhost\n"

existing_containers=$(docker ps --format '{{ .Names }}')
if echo $existing_containers | grep -i $CONTAINER_NAME > /dev/null; then
  printf "Container already present and running. Skipping creation!"
else
  docker run -d -p $PORT:5000 --restart always --name registry registry:3
  docker ps --format '{{.Names}}'
fi
