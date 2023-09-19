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
    banner "$WHITE" "$1"
}

function step() {
    banner "$BLUE" "$1"
}

function execute() {
    local script=$1
    local title=$2
    step "$title"
    sh "$script"
    sleep 5
}


header 'Crypto Shredding with fips'
execute 'step-04-DOCKER' 'Start the docker environment.sh'
execute 'step-05-SH' 'Verify the security provider setup.sh'
execute 'step-06-SH' 'Verify the disabled algorithms.sh'
execute 'step-07-CREATE_VIRTUAL_CLUSTERS' 'Let's create the virtual cluster `teamA`.sh'
execute 'step-08-CREATE_TOPICS' 'Create the `customer-shredding` topic.sh'
execute 'step-09-LIST_TOPICS' 'List topics.sh'
execute 'step-10-ADD_INTERCEPTORS' 'Let's ask gateway to encrypt messages using vault and dynamic keys.sh'
execute 'step-11-LIST_INTERCEPTORS' 'List gateway interceptors.sh'
execute 'step-12-PRODUCE' 'Let's produce sample data for `tom` and `florent`.sh'
execute 'step-13-CONSUME' 'Let's consume the message, and confirm `tom` and `florent` are encrypted.sh'
execute 'step-14-ADD_INTERCEPTORS' 'Let's add the decrypt interceptor to decipher messages.sh'
execute 'step-15-LIST_INTERCEPTORS' 'List gateway interceptors.sh'
execute 'step-16-CONSUME' 'Confirm message from `tom` and `florent` are encrypted.sh'
execute 'step-17-SH' 'Listing keys created in Vault.sh'
execute 'step-18-SH' 'Remove `florent` related keys.sh'
execute 'step-19-CONSUME' 'Let's make sure `florent` data are no more readable!.sh'
execute 'step-20-DOCKER' 'Cleanup the docker environment.sh'
