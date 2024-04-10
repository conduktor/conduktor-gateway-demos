#!/bin/bash

. utils.sh

header 'Topic Concentration'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster teamA"
execute "step-06-CREATE_TOPICS.sh" "Create the topic that will hold concentrated topics"
execute "step-07-CREATE_CONCENTRATION_RULE.sh" "Creating concentration rule for pattern concentrated-.* to hold_many_concentrated_topics"
execute "step-08-CREATE_TOPICS.sh" "Create concentrated topics"
execute "step-09-LIST_TOPICS.sh" "Assert the topics have been created"
execute "step-10-LIST_TOPICS.sh" "Assert the topics have not been created in the underlying kafka cluster"
execute "step-11-CREATE_TOPICS.sh" "Let's continue created virtual topics, but now with many partitions"
execute "step-12-LIST_TOPICS.sh" "Assert they exist in teamA cluster"
execute "step-13-PRODUCE.sh" "Producing 1 message in concentrated-topic-with-10-partitions"
execute "step-14-CONSUME.sh" "Consuming from concentrated-topic-with-10-partitions"
execute "step-15-PRODUCE.sh" "Producing 1 message in concentrated-topic-with-100-partitions"
execute "step-16-CONSUME.sh" "Consuming from concentrated-topic-with-100-partitions"
execute "step-17-CONSUME.sh" "Consuming from concentrated-topic-with-100-partitions"
execute "step-18-DOCKER.sh" "Tearing down the docker environment"
