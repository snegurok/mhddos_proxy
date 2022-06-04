#!/bin/bash

echo i am updated

BRANCH="feature/custom_branch"
PID=""

RED="\033[1;31m"
GREEN="\033[1;32m"
RESET="\033[0m"

PYTHON=$1
SCRIPT_ARGS="${@:2}"

trap 'shutdown' SIGINT SIGQUIT SIGTERM ERR

function shutdown() {
    stop_script
    exit
}

function stop_script() {
  if [ -n "$PID" ];
  then
    kill -INT $PID
    wait $PID
    PID=""
  fi
}

function gitsafe() {
    git "$@" || echo git command failed, simulating success \("$@"\) >&2
}

function update_script() {
    gitsafe reset -q --hard
    gitsafe checkout -q $BRANCH
    gitsafe pull -q
    $PYTHON -m pip install -q -r requirements.txt
}

while true
do

  gitsafe fetch -q origin $BRANCH

  if [ -n "$(gitsafe diff --name-only origin/$BRANCH)" ]
  then
    echo -e "\n${GREEN}[$(date +"%d-%m-%Y %T")] - New version available, updating the script!${RESET}\n"
    stop_script
    update_script
    exec ./runner.sh $PYTHON $SCRIPT_ARGS
  fi

  while [ -z "$PID" ]
  do
    $PYTHON runner.py $SCRIPT_ARGS & PID=$!
    sleep 1
    if ! kill -0 $PID
    then
      PID=""
      echo -e "\n${RED}Error starting - retry in 30 seconds! Ctrl+C to exit${RESET}\n"
      sleep 30
    fi
  done

  sleep 666

done
