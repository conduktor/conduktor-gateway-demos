#!/bin/bash

. utils.sh

header 'Encryption header'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-07-CREATE_TOPICS.sh" "Creating topics customers-full-payload-level-encryption,customers-fields-level-encryption on teamA"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor field level encryption for header"
execute "step-09-ADD_INTERCEPTOR.sh" "Adding interceptor full payload level encryption for header"
execute "step-10-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-11-PRODUCE.sh" "Let's send message with unencrypted json header to customers-fields-level-encryption topic"
execute "step-12-PRODUCE.sh" "Let's send message with unencrypted json header to customers-full-payload-level-encryption topic"
execute "step-13-CONSUME.sh" "Let's consume the message, and confirm \`tom\` header is decrypted in customers-fields-level-encryption topic"
execute "step-14-CONSUME.sh" "Let's consume the message, and confirm the entire \`tom\` header is encrypted in customers-full-payload-level-encryption topic"
execute "step-15-ADD_INTERCEPTOR.sh" "Adding interceptor decrypt"
execute "step-16-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-17-CONSUME.sh" "Confirm header from \`tom\` is decrypted in customers-fields-level-encryption topic"
execute "step-18-CONSUME.sh" "Confirm header from \`tom\` is decrypted in customers-full-payload-level-encryption topic"
execute "step-19-DOCKER.sh" "Tearing down the docker environment"
