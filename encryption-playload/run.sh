#!/bin/sh

. utils.sh

header 'Encryption full playload'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`customers\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`encrypt-full-payload\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-PRODUCE.sh" "Let's send unencrypted json"
execute "step-11-CONSUME.sh" "Let's consume the message, and confirm \`tom\` and \`florent\` data is encrypted"
execute "step-12-ADD_INTERCEPTOR.sh" "Adding interceptor \`decrypt-full-payload\`"
execute "step-13-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-14-CONSUME.sh" "Confirm message from \`tom\` and \`florent\` are decrypted"
execute "step-15-DOCKER.sh" "Tearing down the docker environment"
