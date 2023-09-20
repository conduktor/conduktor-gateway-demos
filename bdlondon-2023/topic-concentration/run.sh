#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color

function banner() {
    printf "$1# $2$NC\n" | pv -qL 20
}

function header() {
    banner "$RED" "$1"
}

function step() {
    banner "$BLUE" "$1"
}

function execute() {
    local script=$1
    local title=$2
    step "$title"
    sh type.sh "$script"
    echo
}


header 'Topic Concentration'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-07-CREATE_TOPICS.sh" "Create the topic that will hold virtual topics"
execute "step-08-ADD_TOPIC_MAPPING.sh" "Creating mapping from \`concentrated-.*\` to \`hold-many-concentrated-topics\`"
execute "step-09-CREATE_TOPICS.sh" "Create concentrated topics"
execute "step-10-LIST_TOPICS.sh" "Assert the topics have been created"
execute "step-11-LIST_TOPICS.sh" "Assert the topics have not been created in the underlying kafka cluster"
execute "step-12-CREATE_TOPICS.sh" "Let's continue created virtual topics, but now with many partitions"
execute "step-13-LIST_TOPICS.sh" "Assert they exist in \`teamA\` cluster"
execute "step-14-PRODUCE.sh" "Producing 1message in \`concentrated-topic-with-10-partitions\`"
execute "step-15-CONSUME.sh" "Consuming from \`concentrated-topic-with-10-partitions\`"
execute "step-16-PRODUCE.sh" "Producing 1message in \`concentrated-topic-with-100-partitions\`"
execute "step-17-CONSUME.sh" "Consuming from \`concentrated-topic-with-100-partitions\`"
execute "step-19-DOCKER.sh" "Cleanup the docker environment"
