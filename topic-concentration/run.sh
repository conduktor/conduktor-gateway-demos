#!/bin/sh

. utils.sh

header 'Topic Concentration'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Create the topic that will hold virtual topics"
execute "step-08-CREATE_CONCENTRATED_TOPIC.sh" ""
execute "step-09-CREATE_TOPICS.sh" "Create concentrated topics"
execute "step-10-LIST_TOPICS.sh" "Assert the topics have been created"
execute "step-11-LIST_TOPICS.sh" "Assert the topics have not been created in the underlying kafka cluster"
execute "step-12-CREATE_TOPICS.sh" "Let's continue created virtual topics, but now with many partitions"
execute "step-13-LIST_TOPICS.sh" "Assert they exist in \`teamA\` cluster"
execute "step-14-PRODUCE.sh" "Producing 1 message in \`concentrated-topic-with-10-partitions\`"
execute "step-15-CONSUME.sh" "Consuming from \`concentrated-topic-with-10-partitions\`"
execute "step-16-PRODUCE.sh" "Producing 1 message in \`concentrated-topic-with-100-partitions\`"
execute "step-17-CONSUME.sh" "Consuming from \`concentrated-topic-with-100-partitions\`"
execute "step-18-CONSUME.sh" "Consuming from \`concentrated-topic-with-100-partitions\`"
execute "step-19-DOCKER.sh" "Tearing down the docker environment"
