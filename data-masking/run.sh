#!/bin/bash

. utils.sh

header 'Data Masking'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor data-masking"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-09-PRODUCE.sh" "Let's send json"
execute "step-10-CONSUME.sh" "Let's consume the message, and confirm tom and laura fields are masked"
execute "step-11-REMOVE_INTERCEPTORS.sh" "Remove interceptor data-masking"
execute "step-12-CONSUME.sh" "Let's consume the message, and confirm tom and laura fields no more masked"
execute "step-13-DOCKER.sh" "Tearing down the docker environment"
