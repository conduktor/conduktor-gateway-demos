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


header 'Throughput'
execute "step-04-DOCKER.sh" "Startup the docker environment"
execute "step-05-CREATE_TOPICS.sh" "Creating topic \`physical-kafka\`"
execute "step-06-SH.sh" "Let's use \`kafka-producer-perf-test\` that comes bundled with Kafka"
execute "step-07-CREATE_VIRTUAL_CLUSTERS.sh" "Creating virtual cluster \`teamA\`"
execute "step-09-CREATE_TOPICS.sh" "Creating topic \`via-gateway\`"
execute "step-10-SH.sh" "Let's use \`kafka-producer-perf-test\` that comes bundled with Kafka"
execute "step-11-DOCKER.sh" "Cleanup the docker environment"
