#!/bin/bash

. utils.sh

header 'SNI Routing'
execute "step-04-SH.sh" ""
execute "step-05-DOCKER.sh" "Starting the docker environment"
execute "step-06-SH.sh" "Create a topic"
execute "step-07-SH.sh" "Produce a record to clientTopic using gateway1"
execute "step-08-SH.sh" "Produce a record to clientTopic using gateway2"
execute "step-09-SH.sh" "Consume records from clientTopic"
execute "step-10-DOCKER.sh" "Tearing down the docker environment"
