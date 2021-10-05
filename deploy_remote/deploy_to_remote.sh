#!/bin/bash

# Expects User and host command line arguments 
if [ "$1" == "" ]; then
    echo "Missing ssh user as first command line argument."
    echo "Please run this as ./deploy_remote/deploy_to_remote.sh {SSH_USER} {HOSTNAME/HOST_IP}."
    exit 0
fi

if [ "$2" == "" ]; then
    echo "Missing hostname or host IP as second command line argument."
    echo "Please run this as ./deploy_remote/deploy_to_remote.sh {SSH_USER} {HOSTNAME/HOST_IP}."
    exit 0
fi
USER=$1
HOST=$2

# Check the SSH connection
ssh_connect=$(ssh -o BatchMode=yes -o ConnectTimeout=5 ${USER}@${HOST} echo ok 2>&1)
if [[ $ssh_connect != ok ]]; then
    echo "Unable to connect to ${USER}@${HOST}! Please check your SSH config."
    exit 0
fi


DOCKER_BUILDKIT=1 \
docker build \
    -t musicbot \
    -t musicbot:deploy \
    .

# Push image to remote machine (and use pv as a status bar is possible)
if ! command -v pv &> /dev/null; then
    docker save musicbot:deploy | bzip2 | ssh ${USER}@${HOST} docker load
else
    docker save musicbot:deploy | bzip2 | pv | ssh ${USER}@${HOST} docker load
fi

# Create remote context and deploy it to that context
docker context create remote --docker "host=ssh://${USER}@${HOST}"
docker-compose --context remote up -d
