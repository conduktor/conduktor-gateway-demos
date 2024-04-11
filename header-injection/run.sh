#!/bin/bash

. utils.sh

header 'Header Injection'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic users on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor inject-headers"
execute "step-08-PRODUCE.sh" "Send tom and laura into users"
execute "step-09-CONSUME.sh" "Verify tom and laura have the corresponding headers"
execute "step-10-ADD_INTERCEPTOR.sh" "Adding interceptor remove-headers"
execute "step-11-CONSUME.sh" "Verify tom and laura have the corresponding headers"
execute "step-12-REMOVE_INTERCEPTORS.sh" "Remove interceptor remove-headers"
execute "step-13-CONSUME.sh" "Verify tom and laura have X-MY-KEY back"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
