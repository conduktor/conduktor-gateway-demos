#!/bin/bash

. utils.sh

header 'Oauth'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-06-CREATE_TOPICS.sh" "Creating topic cars on gateway1"
execute "step-07-LIST_TOPICS.sh" "Listing topics in gateway1"
execute "step-08-DOCKER.sh" "Tearing down the docker environment"
