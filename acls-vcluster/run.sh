#!/bin/bash

. utils.sh

header 'ACLs in VCLUSTER mode'
execute "step-04-DOCKER.sh" "Starting the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster aclCluster"
execute "step-06-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster aclCluster"
execute "step-07-CREATE_VIRTUAL_CLUSTER.sh" "Creating virtual cluster aclCluster"
execute "step-08-ADD_INTERCEPTOR.sh" "Adding interceptor acl"
execute "step-09-CREATE_TOPICS.sh" "Try to create a topic as a consumer"
execute "step-10-CREATE_TOPICS.sh" "Creating topic restricted-topic on aclCluster"
execute "step-11-LIST_TOPICS.sh" "List topics with consumer-sa does not throw error but gets no topic"
execute "step-12-SH.sh" "Let's give read-access to test-topic for consumer SA"
execute "step-13-CONSUME.sh" "Consuming from _conduktor_gateway_acls"
execute "step-14-SH.sh" "Let's give read-access to fixed console-consumer for consumer SA"
execute "step-15-LIST_TOPICS.sh" "Listing topics in aclCluster"
execute "step-16-SH.sh" "Give read/write access to test-topic to producer SA"
execute "step-17-LIST_TOPICS.sh" "Listing topics in aclCluster"
execute "step-18-PRODUCE.sh" "Let's write into test-topic (producer)"
execute "step-19-CONSUME.sh" "Let's consume from test-topic (consumer)"
execute "step-20-PRODUCE.sh" "Consumer-sa cannot write into the test-topic"
execute "step-21-DOCKER.sh" "Tearing down the docker environment"
