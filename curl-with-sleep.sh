#!/bin/bash


while true; do
  curl -o /dev/null -s -w "%{http_code}\n" http://100.76.6.76:30008/
  sleep 1
  done
