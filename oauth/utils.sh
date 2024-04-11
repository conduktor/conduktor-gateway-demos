RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color


function type() {
  local file="$1"
  local chars=$(cat $file| wc -c)

  printf "${WHITE}"
  if [ "$chars" -lt 70 ] ; then
      cat $file | pv -qL 30
  elif [ "$chars" -lt 100 ] ; then
      cat $file | pv -qL 50
  elif [ "$chars" -lt 250 ] ; then
      cat $file | pv -qL 100
  elif [ "$chars" -lt 500 ] ; then
      cat $file | pv -qL 200
  else
      cat $file | pv -qL 400
  fi
  printf "${NC}\n"
}

function banner() {
    if [ -z "${NO_PAUSE}" ] && [ -z "${SPEED}" ]; then
      echo -e "$1# $2$NC\n" | pv -qL 20
    else
      echo -e "$1# $2$NC\n"
    fi
}

function header() {
    banner "$RED" "$1"
}

function step() {
    banner "$BLUE" "$1"
}

function pause() {
    if [ -z "${NO_PAUSE}" ] && [ -z "${SPEED}" ]; then
        read -p "continue?"
        echo -e "\033[1A\033[K"
        echo
    else
        if  [ -z "${SPEED}" ]; then
          sleep 2
        fi
    fi
}

function execute() {
    local script=$1
    local title=$2

    step "$title"
    sleep 2
    type "$script"
    sh $script
    echo
}