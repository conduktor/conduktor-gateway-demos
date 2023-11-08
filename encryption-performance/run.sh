#!/bin/sh

. utils.sh

header 'Encryption performance'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Creating topic \`customers\` on \`teamA\`"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor \`encrypt\`"
execute "step-09-ADD_INTERCEPTOR.sh" "Adding interceptor \`decrypt\`"
execute "step-10-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-11-SH.sh" "Running \`kafka-producer-perf-test\` bundled with Apache Kafka"
execute "step-12-DOCKER.sh" "Tearing down the docker environment"
