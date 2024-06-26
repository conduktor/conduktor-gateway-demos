#!/bin/bash

. utils.sh

header 'mTLS and User Mapping'
execute "step-04-SH.sh" "Generate self-signed ssl certificates"
execute "step-05-DOCKER.sh" "Starting the docker environment"
execute "step-06-ADD_USER_MAPPING.sh" "Adding user mapping for CN=username"
execute "step-07-CREATE_TOPICS.sh" "Creating topic foo on gateway1"
execute "step-08-LIST_TOPICS.sh" "Listing topics in gateway1"
execute "step-09-LIST_TOPICS.sh" "Listing topics in kafka1"
execute "step-10-DOCKER.sh" "Tearing down the docker environment"
