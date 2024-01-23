#!/bin/sh

. utils.sh

header 'SQL topics'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`cars\` on \`teamA\`"
execute "step-08-PRODUCE.sh" "Producing 2 messages in \`cars\`"
execute "step-09-CONSUME.sh" "Consuming from \`cars\`"
execute "step-10-ADD_INTERCEPTOR.sh" "Adding interceptor \`red-cars\`"
execute "step-11-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-12-CONSUME.sh" "Consume from the virtual topic \`red-cars\`"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
