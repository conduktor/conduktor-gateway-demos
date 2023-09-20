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


header 'Schema Id validation'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-06-CREATE_TOPICS.sh" "Creating topic \`users\`"
execute "step-07-LIST_TOPICS.sh" "Listing topics in \`teamA\`"
execute "step-08-ADD_INTERCEPTORS.sh" "Adding interceptor \`schema-id\` in \`gateway1\`"
execute "step-09-LIST_INTERCEPTORS.sh" "Listing interceptors for \`teamA\`"
execute "step-11-CONSUME.sh" "Consuming from \`users\`"
execute "step-12-SH.sh" ""
execute "step-13-SH.sh" ""
execute "step-14-CONSUME.sh" "Consuming from \`users\`"
execute "step-15-DOCKER.sh" "Cleanup the docker environment"
