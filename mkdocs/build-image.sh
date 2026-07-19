#!/bin/bash

printf "Listing files in current directory\n"
ls

printf "Building the docker image for meridian\n"
docker build -t localhost:5000/meridian -f Dockerfile ./
