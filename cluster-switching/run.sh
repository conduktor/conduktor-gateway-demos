#!/bin/sh
echo 'Start the docker environment'
sh step-06-DOCKER.sh

echo 'Create teamA virtual cluster'
sh step-07-CREATE_VIRTUAL_CLUSTERS.sh

echo 'Create topic users'
sh step-09-CREATE_TOPICS.sh

echo 'Send tom and florent into topic users'
sh step-10-PRODUCE.sh

echo ''
sh step-11-LIST_TOPICS.sh

echo 'Wait for mirror maker to do its job on gateway internal topic'
sh step-12-CONSUME.sh

echo 'Wait for mirror maker to do its job on user topics'
sh step-13-CONSUME.sh

echo 'Assert mirror maker did its job'
sh step-14-LIST_TOPICS.sh

echo 'Call the failover switch api on gateway1'
sh step-15-FAILOVER.sh

echo 'Call the failover switch api on gateway2'
sh step-16-FAILOVER.sh

echo 'Produce thibault into users, it should hit only failover-kafka'
sh step-17-PRODUCE.sh

echo 'Verify we can read florent, and tom (via mirror maker) and thibault (via switch)'
sh step-18-CONSUME.sh

echo 'Verify thibaut is not in main kafka'
sh step-19-CONSUME.sh

echo 'Verify thibaut is in failover'
sh step-20-CONSUME.sh

echo 'Cleanup the docker environment'
sh step-21-DOCKER.sh

