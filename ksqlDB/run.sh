#!/bin/sh

. utils.sh

header 'ksqldb'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-06-CREATE_CONCENTRATED_TOPIC.sh" ""
execute "step-07-SH.sh" "Start ksqlDB"
execute "step-08-LIST_TOPICS.sh" "Listing topics in \`teamA\`"
execute "step-09-LIST_TOPICS.sh" "Listing topics in \`kafka1\`"
execute "step-11-SH.sh" ""
execute "step-12-LIST_TOPICS.sh" "Listing topics in \`teamA\`"
execute "step-13-LIST_TOPICS.sh" "Listing topics in \`kafka1\`"
execute "step-14-DOCKER.sh" "Tearing down the docker environment"
