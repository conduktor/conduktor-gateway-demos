#!/bin/bash

. utils.sh

header 'Encryption for third party'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_VIRTUAL_CLUSTER.sh" "Let's create a service account third-party for teamA virtual cluster"
execute "step-07-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor encrypt-on-consume"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-10-PRODUCE.sh" "Let's send unencrypted json"
execute "step-11-CONSUME.sh" "Confirm tom and laura data is not encrypted for teamA"
execute "step-12-CONSUME.sh" "Confirm tom and laura data is encrypted for third-party"
execute "step-13-DOCKER.sh" "Tearing down the docker environment"
