#!/bin/bash

. utils.sh

header 'SQL topics in GATEWAY_SECURITY mode'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster passthrough"
execute "step-06-CREATE_TOPICS.sh" "Creating topic cars on passthrough"
execute "step-07-PRODUCE.sh" "Producing 2 messages in cars"
execute "step-08-CONSUME.sh" "Consuming from cars"
execute "step-09-ADD_INTERCEPTOR.sh" "Adding interceptor red-cars"
execute "step-10-LIST_INTERCEPTORS.sh" "Listing interceptors for passthrough"
execute "step-11-CONSUME.sh" "Consume from the virtual topic red-cars"
execute "step-13-DOCKER.sh" "Tearing down the docker environment"
