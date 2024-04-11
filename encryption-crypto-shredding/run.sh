#!/bin/bash

. utils.sh

header 'Encryption with Crypto Shredding'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Creating topic customers-shredding on teamA"
execute "step-07-LIST_TOPICS.sh" "Listing topics in teamA"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor crypto-shredding-encrypt"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-10-PRODUCE.sh" "Let's produce sample data for tom and laura"
execute "step-11-CONSUME.sh" "Let's consume the message, and confirm tom and laura are encrypted"
execute "step-12-ADD_INTERCEPTOR.sh" "Adding interceptor crypto-shredding-decrypt"
execute "step-13-LIST_INTERCEPTORS.sh" "Listing interceptors for teamA"
execute "step-14-CONSUME.sh" "Confirm message from tom and laura are encrypted"
execute "step-15-SH.sh" "Listing keys created in Vault"
execute "step-16-SH.sh" "Remove laura related keys"
execute "step-17-CONSUME.sh" "Let's make sure laura data are no more readable!"
execute "step-18-DOCKER.sh" "Tearing down the docker environment"
