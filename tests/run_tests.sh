#!/bin/bash

# prerequisites:
# Docker
# all tests: ./run_tests.sh no_ssl nginx nginx_no_x_forward nginx_444 ei redis_1 redis_120

# workaround to have jq available in Docker Toolbox for Windows
shopt -s expand_aliases
source ~/.bashrc

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $scriptDir

docker build -t tester:latest .

if [ "$?" -ne 0 ]; then
  notify "@jannis.warnat tester image could not be built"
  exit 1
fi

function notify
{
if [ "$POST_CHAT_MESSAGE" = true ] ; then
   cd "$scriptDir"
  ./postChatMessage.sh "$1"
fi
}

cd "$scriptDir/.."
docker build -f Dockerfile-npm -t docker.linksmart.eu/bgw:npm .

if [ "$?" -ne 0 ]; then
  notify "@jannis.warnat Intermediate image could not be built"
  exit 1
fi

docker build -f Dockerfile-test -t docker.linksmart.eu/bgw:snapshot .
#docker build -t docker.linksmart.eu/bgw:snapshot . # Dockerfile for Bamboo

if [ "$?" -ne 0 ]; then
  notify "@jannis.warnat Snapshot image could not be built"
  exit 1
fi

cd "$scriptDir/backend"
docker-compose up -d

CA=$1

for test in "$@"
do
    cd "$scriptDir/$test"
    docker-compose down
done

declare -A runtimes

for test in "$@"
do
    start=$(date +%s)

    cd "$scriptDir/$test"
    echo "current directory is $(pwd)"
    docker-compose up -d bgw

    if [[ $test == *"nginx"* ]]; then
      docker-compose up -d nginx
    fi

    docker-compose up --exit-code-from tester tester

    #workaround until Windows 10 and most current docker-compose is available (hopefully)
    exitCode=$(docker inspect $(docker-compose ps -q tester) | jq '.[0].State.ExitCode')
    #if [ "$?" -ne 0 ]; then
    if [ "$exitCode" -ne 0 ]; then
        notify "@jannis.warnat Tester failed for test $test"
        exit 1
    fi

    end=$(date +%s)
    docker-compose logs bgw &> "./lastRun.log"

    docker-compose down

    runtimes[$test]=$((end-start))
done

for test in "$@"
do
    echo "Runtime for $test: ${runtimes[$test]}"
done

printf "\n"
echo "All tests successful :-)!"
cd "$scriptDir"
notify "@jannis.warnat All tests successful!"
exit 0