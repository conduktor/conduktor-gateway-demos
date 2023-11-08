#!/bin/sh

. utils.sh

header 'Chaos Simulate Invalid Schema Id'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`with-schema\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`simulate-invalid-schema-id\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-SH.sh" "Let's produce some records to our created topic"
execute "step-11-SH.sh" "Let's consume them with a schema aware consumer."
execute "step-12-DOCKER.sh" "Tearing down the docker environment"
