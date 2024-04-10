#!/bin/bash

. utils.sh

header 'Chaos Simulate Broken Brokers'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic my-topic on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor simulate-broken-brokers"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-09-SH.sh" "Let's produce some records to our created topic and observe some errors being injected by Conduktor Gateway."
execute "step-10-REMOVE_INTERCEPTORS.sh" "Remove interceptor simulate-broken-brokers"
execute "step-11-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-12-SH.sh" "Let's produce some records to our created topic with no chaos"
execute "step-13-DOCKER.sh" "Tearing down the docker environment"
