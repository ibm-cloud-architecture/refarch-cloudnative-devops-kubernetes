#!/bin/bash

# Getting config values from secret
export BLUEMIX_API_KEY=$(cat /var/run/secrets/bx-auth-secret/BLUEMIX_API_KEY)

# Login to Bluemix CLI
printf "\n\nLogging into Bluemix CLI\n"
bx login

# Init Container Service
printf "\n\nInitializing plug-ins\n"
bx cs init
bx cr login

export KUBE_API_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
export REGISTRY_NAMESPACE=$(bx cr namespace-list | egrep -v 'Listing namespaces...' | egrep -v '^OK$' | sed -e '/^Namespace   $/d' | sed -e '/^\s*$/d' | tr -d '[:space:]')

helm init
# This keeps the container alive
exec "$@"
