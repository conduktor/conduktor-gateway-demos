#!/bin/sh

. utils.sh

header 'Full payload encryption with external storage'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`customers\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`encrypt\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-10-CONSUME.sh" "Let's verify there's a single entry in \`_encryptionConfig\`"
execute "step-11-PRODUCE.sh" "Let's send unencrypted json"
execute "step-12-CONSUME.sh" "Let's consume the message, and confirm \`tom\` and \`florent\` data is encrypted"
execute "step-13-ADD_INTERCEPTOR.sh" "Adding interceptor \`decrypt\`"
execute "step-14-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-15-CONSUME.sh" "Confirm message from \`tom\` and \`florent\` are decrypted"
execute "step-16-CONSUME.sh" "Read the underlying kafka data to reveal the magic"
execute "step-17-DOCKER.sh" "Tearing down the docker environment"
