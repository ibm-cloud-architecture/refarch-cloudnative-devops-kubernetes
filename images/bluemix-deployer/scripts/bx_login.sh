#!/bin/bash

if [ -z "${BX_API_ENDPOINT}" ]; then
    echo "Environment variable BX_API_ENDPOINT not defined!"
    exit 1
fi

if [ -z "${BX_SPACE}" ]; then
    echo "Environment variable BX_SPACE not defined!"
    exit 1
fi

if [ -z "${BLUEMIX_API_KEY}" ]; then
    echo "Environment variable BLUEMIX_API_KEY not defined!"
    exit 1
fi

if [ "${LOGGED_IN}" == "true" ]; then
    echo "Already logged in to Bluemix"
else
    bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}

    export LOGGED_IN=true
fi
