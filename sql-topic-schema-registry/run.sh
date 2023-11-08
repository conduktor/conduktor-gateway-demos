#!/bin/sh

. utils.sh

header 'SQL topic with Avro'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-06-CREATE_TOPICS.sh" "Creating topic \`cars\` on \`teamA\`"
execute "step-07-LIST_TOPICS.sh" "Listing topics in \`teamA\`"
execute "step-08-SH.sh" "Produce avro payload"
execute "step-09-SH.sh" "Consume the avro payload back"
execute "step-10-CREATE_TOPICS.sh" "Creating topic \`red-cars\` on \`teamA\`"
execute "step-11-ADD_INTERCEPTOR.sh" "Adding interceptor \`red-cars\`"
execute "step-12-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-13-SH.sh" ""
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
