#!/bin/bash

. utils.sh

header 'Client Id validation'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic users on teamA"
execute "step-07-LIST_TOPICS.sh" "Listing topics in teamA"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor client-id"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-10-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-11-SH.sh" "Let's update the client id to match the convention"
execute "step-12-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-13-AUDITLOG.sh" "Check in the audit log that produce was denied"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
