#!/bin/sh

. utils.sh

header 'Chaos Simulate Message Corruption'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`with-random-bytes\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`simulate-massage-corruption\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-PRODUCE.sh" "Send message to our created topic"
execute "step-11-CONSUME.sh" "Let's consume the message, and confirm message was appended random bytes"
execute "step-12-DOCKER.sh" "Tearing down the docker environment"
