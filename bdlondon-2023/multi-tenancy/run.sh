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


header 'Multi tenancy'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-LIST_TOPICS.sh" "Listing topics in \`kafka1\`"
execute "step-06-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`london\`"
execute "step-07-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`paris\`"
execute "step-08-CREATE_TOPICS.sh" "Creating topic \`londonTopic\`"
execute "step-09-CREATE_TOPICS.sh" "Creating topic \`parisTopic\`"
execute "step-10-LIST_TOPICS.sh" "Listing topics in \`london\`"
execute "step-11-LIST_TOPICS.sh" "Listing topics in \`paris\`"
execute "step-12-PRODUCE.sh" "Producing 1message in \`londonTopic\`"
execute "step-13-CONSUME.sh" "Consuming from \`londonTopic\`"
execute "step-14-PRODUCE.sh" "Producing 1message in \`parisTopic\`"
execute "step-15-CONSUME.sh" "Consuming from \`parisTopic\`"
execute "step-16-CREATE_TOPICS.sh" "Creating topic \`existingLondonTopic\`"
execute "step-17-PRODUCE.sh" "Producing 1message in \`existingLondonTopic\`"
execute "step-18-SH.sh" ""
execute "step-19-LIST_TOPICS.sh" "Listing topics in \`london\`"
execute "step-20-CREATE_TOPICS.sh" "Creating topic \`existingSharedTopic\`"
execute "step-21-PRODUCE.sh" "Producing 1message in \`existingSharedTopic\`"
execute "step-22-SH.sh" ""
execute "step-23-LIST_TOPICS.sh" "Listing topics in \`london\`"
execute "step-24-CONSUME.sh" "Consuming from \`existingLondonTopic\`"
execute "step-25-CONSUME.sh" "Consuming from \`existingSharedTopic\`"
execute "step-26-SH.sh" ""
execute "step-27-LIST_TOPICS.sh" "Listing topics in \`paris\`"
execute "step-28-CONSUME.sh" "Consuming from \`existingSharedTopic\`"
execute "step-29-DOCKER.sh" "Cleanup the docker environment"
