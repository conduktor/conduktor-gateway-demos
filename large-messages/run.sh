#!/bin/bash

. utils.sh

header 'Large message support'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-07-SH.sh" "Let's create a bucket"
execute "step-08-CREATE_TOPICS.sh" "Creating topic large-messages on teamA"
execute "step-09-ADD_INTERCEPTOR.sh" "Adding interceptor large-messages"
execute "step-10-SH.sh" "Let's create a large message"
execute "step-11-SH.sh" "Sending large pdf file through kafka"
execute "step-12-SH.sh" "Let's read the message back"
execute "step-13-SH.sh" "Let's compare the files"
execute "step-14-SH.sh" "Let's look at what's inside minio"
execute "step-15-CONSUME.sh" "Consuming from teamAlarge-messages"
execute "step-16-DOCKER.sh" "Tearing down the docker environment"
