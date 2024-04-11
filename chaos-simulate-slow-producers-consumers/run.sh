#!/bin/bash

. utils.sh

header 'Chaos Simulate Slow Producers & Consumers'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic slow-topic on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor simulate-slow-producer-consumers"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-09-SH.sh" "Let's produce some records to our created topic"
execute "step-10-DOCKER.sh" "Tearing down the docker environment"
