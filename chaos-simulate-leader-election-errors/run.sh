#!/bin/sh

. utils.sh

header 'Chaos Simulate Leader Election Errors'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`my-topic\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`simulate-leader-elections-errors\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-SH.sh" "Let's produce some records to our created topic."
execute "step-11-DOCKER.sh" "Tearing down the docker environment"
