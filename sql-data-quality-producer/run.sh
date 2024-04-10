#!/bin/bash

. utils.sh

header 'SQL Based Data Quality Producer'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic cars on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor cars-quality"
execute "step-08-PRODUCE.sh" "Producing an invalid car"
execute "step-09-PRODUCE.sh" "Producing an invalid car based on key"
execute "step-10-PRODUCE.sh" "Producing a valid car"
execute "step-11-CONSUME.sh" "Consuming from cars"
execute "step-12-CONSUME.sh" "Confirm all invalid cars are in the dead letter topic"
execute "step-13-AUDITLOG.sh" "Check in the audit log that messages denial were captured"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
