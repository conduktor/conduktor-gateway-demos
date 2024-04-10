#!/bin/bash

. utils.sh

header 'Audit'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-ADD_INTERCEPTOR.sh" "Adding interceptor guard-on-produce"
execute "step-07-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-08-CREATE_TOPICS.sh" "Creating topic cars on teamA"
execute "step-09-PRODUCE.sh" "Produce sample data to our cars topic without the right policies"
execute "step-10-AUDITLOG.sh" "Check in the audit log that produce was denied"
execute "step-11-DOCKER.sh" "Tearing down the docker environment"
