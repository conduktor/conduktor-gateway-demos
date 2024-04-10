#!/bin/bash

. utils.sh

header 'SQL topics'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_TOPICS.sh" "Creating topic cars on gateway1"
execute "step-06-PRODUCE.sh" "Producing 2 messages in cars"
execute "step-07-CONSUME.sh" "Consuming from cars"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor red-cars"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for passthrough"
execute "step-10-CONSUME.sh" "Consume from the virtual topic red-cars"
execute "step-12-DOCKER.sh" "Tearing down the docker environment"
