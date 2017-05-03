#!/bin/bash
set -x
# Docker Stuff
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- docker "$@"
fi

# if our command is a valid Docker subcommand, let's invoke it through Docker instead
# (this allows for "docker run docker ps", etc)
if docker help "$1" > /dev/null 2>&1; then
	set -- docker "$@"
fi

# if we have "--link some-docker:docker" and not DOCKER_HOST, let's set DOCKER_HOST automatically
if [ -z "$DOCKER_HOST" -a "$DOCKER_PORT_2375_TCP" ]; then
	export DOCKER_HOST='tcp://docker:2375'
fi

# Bluemix Stuff
if [ -f "/var/run/secrets/bluemix-api-key/api-key" ]; then
    BLUEMIX_API_KEY=`cat /var/run/secrets/bluemix-api-key/api-key`
fi

bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}

# initialize docker using container registry secret
bx plugin install container-registry -r Bluemix
bx cr login

exec "$@"
