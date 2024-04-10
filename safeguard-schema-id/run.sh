#!/bin/bash

. utils.sh

header 'Schema Id validation'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic users on teamA"
execute "step-07-LIST_TOPICS.sh" "Listing topics in teamA"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor schema-id"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-10-PRODUCE.sh" "Producing 1 message in users"
execute "step-11-CONSUME.sh" "Consuming from users"
execute "step-12-SH.sh" "Send avro message"
execute "step-13-SH.sh" "Get subjects"
execute "step-14-CONSUME.sh" "Consuming from users"
execute "step-15-DOCKER.sh" "Tearing down the docker environment"
