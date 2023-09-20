function type_and_execute() {
  local GREEN="\033[0;32m"
  local WHITE='\033[0;97m'
  local RESET="\033[0m"
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
  echo "${RESET}"

  sh $file
}

type_and_execute "$1"
