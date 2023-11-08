#!/bin/sh

. utils.sh

header 'Encryption for third party'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_VIRTUAL_CLUSTER.sh" "Let's create a service account \`third-party\` for \`teamA\` virtual cluster"
execute "step-08-CREATE_TOPICS.sh" "Creating topic \`customers\` on \`teamA\`"
execute "step-09-ADD_INTERCEPTOR.sh" "Adding interceptor \`encrypt-on-consume\`"
execute "step-10-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-11-PRODUCE.sh" "Let's send unencrypted json"
execute "step-12-CONSUME.sh" "Confirm \`tom\` and \`florent\` data is not encrypted for \`teamA\`"
execute "step-13-CONSUME.sh" "Confirm \`tom\` and \`florent\` data is encrypted for \`third-party\`"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
