#!/bin/bash

if [ -z "${BX_API_ENDPOINT}" ]; then
    echo "Environment variable BX_API_ENDPOINT not defined!"
    exit 1
fi

if [ ! -z "${BX_ORG}" ]; then
    BX_ARG="${BX_ARG} -o ${BX_ORG}"
fi

if [ ! -z "${BX_SPACE}" ]; then
    BX_ARG="${BX_ARG} -s ${BX_SPACE}"
fi

if [ -z "${BLUEMIX_API_KEY}" ]; then
    echo "Environment variable BLUEMIX_API_KEY not defined!"
    exit 1
fi

if [ "${LOGGED_IN}" == "true" ]; then
    echo "Already logged in to Bluemix"
else
    bx login -a ${BX_API_ENDPOINT} ${BX_ARG}

    export LOGGED_IN=true
fi
