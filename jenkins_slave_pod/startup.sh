#!/bin/bash

# Getting config values from secret
CF_EMAIL=$(cat /var/run/secrets/bx-auth-secret/CF_EMAIL)
CF_PASSWORD=$(cat /var/run/secrets/bx-auth-secret/CF_PASSWORD)
CF_ACCOUNT=$(cat /var/run/secrets/bx-auth-secret/CF_ACCOUNT)
CF_ORG=$(cat /var/run/secrets/bx-auth-secret/CF_ORG)
CF_SPACE=$(cat /var/run/secrets/bx-auth-secret/CF_SPACE)

# Login to Bluemix CLI
printf "\n\nLogging into Bluemix CLI\n"
bx login -a api.ng.bluemix.net -u ${CF_EMAIL} -p ${CF_PASSWORD} -c ${CF_ACCOUNT} -o ${CF_ORG} -s ${CF_SPACE}

# Init Container Service
printf "\n\nInitializing plug-ins\n"
bx cs init
bx cr login

export KUBE_API_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
export REGISTRY_NAMESPACE=$(bx cr namespace-list | egrep -v 'Listing namespaces...' | egrep -v '^OK$' | sed -e '/^Namespace   $/d' | sed -e '/^\s*$/d' | tr -d '[:space:]')

# This keeps the container alive
exec "$@"