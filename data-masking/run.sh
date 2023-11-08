#!/bin/sh

. utils.sh

header 'Data Masking'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`customers\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`data-masking\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-PRODUCE.sh" "Let's send json"
execute "step-11-CONSUME.sh" "Let's consume the message, and confirm \`tom\` and \`florent\` fields are masked"
execute "step-12-REMOVE_INTERCEPTORS.sh" "Remove interceptor \`data-masking\`"
execute "step-13-CONSUME.sh" "Let's consume the message, and confirm \`tom\` and \`florent\` fields no more masked"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
