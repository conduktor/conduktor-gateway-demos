#!/bin/sh

. utils.sh

header 'Header Injection'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`users\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`inject-headers\`"
execute "step-09-PRODUCE.sh" "Send tom and florent into \`users\`"
execute "step-10-CONSUME.sh" "Verify tom and florent have the corresponding headers"
execute "step-11-ADD_INTERCEPTOR.sh" "Adding interceptor \`remove-headers\`"
execute "step-12-CONSUME.sh" "Verify tom and florent have the corresponding headers"
execute "step-13-REMOVE_INTERCEPTORS.sh" "Remove interceptor \`remove-headers\`"
execute "step-14-CONSUME.sh" "Verify \`tom\` and \`florent\` have \`X-MY-KEY\` back"
execute "step-15-DOCKER.sh" "Tearing down the docker environment"
