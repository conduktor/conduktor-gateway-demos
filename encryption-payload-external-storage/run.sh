#!/bin/bash

. utils.sh

header 'Encryption Full Payload with external storage'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic customers on teamA"
execute "step-07-ADD_INTERCEPTOR.sh" "Adding interceptor encrypt"
execute "step-08-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-09-CONSUME.sh" "Let's verify there's a single entry in _encryptionConfig"
execute "step-10-PRODUCE.sh" "Let's send unencrypted json"
execute "step-11-CONSUME.sh" "Let's consume the message, and confirm tom and laura data is encrypted"
execute "step-12-ADD_INTERCEPTOR.sh" "Adding interceptor decrypt"
execute "step-13-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-14-CONSUME.sh" "Confirm message from tom and laura are decrypted"
execute "step-15-CONSUME.sh" "Read the underlying kafka data to reveal the magic"
execute "step-16-DOCKER.sh" "Tearing down the docker environment"
