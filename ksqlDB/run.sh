#!/bin/bash

. utils.sh

header 'ksqldb'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Create the topic that will hold virtual topics"
execute "step-07-CREATE_TOPICS.sh" "Create the topic that will hold compacted virtual topics"
execute "step-08-CREATE_CONCENTRATION_RULE.sh" "Creating concentration rule for pattern concentrated-.* to concentrated"
execute "step-09-SH.sh" "Start ksqlDB"
execute "step-10-LIST_TOPICS.sh" "Listing topics in teamA"
execute "step-11-LIST_TOPICS.sh" "Listing topics in kafka1"
execute "step-13-SH.sh" "Execute ksql script"
execute "step-14-LIST_TOPICS.sh" "Listing topics in teamA"
execute "step-15-LIST_TOPICS.sh" "Listing topics in kafka1"
execute "step-16-DOCKER.sh" "Tearing down the docker environment"
