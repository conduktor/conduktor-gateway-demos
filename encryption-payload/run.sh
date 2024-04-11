#!/bin/bash

. utils.sh

header 'Encryption full payload'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor encrypt-full-payload"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-09-PRODUCE.sh" "Let's send unencrypted json"
execute "step-10-CONSUME.sh" "Let's consume the message, and confirm tom and laura data is encrypted"
execute "step-11-ADD_INTERCEPTOR.sh" "Adding interceptor decrypt-full-payload"
execute "step-12-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-13-CONSUME.sh" "Confirm message from tom and laura are decrypted"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
