#!/bin/bash
#set -e
#set -o pipefail

# Add user to k8s using service account, no RBAC (must create RBAC after this script)
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
 echo "usage: $0 <service_account_name> <namespace>"
 exit 1
fi

SERVICE_ACCOUNT_NAME=$1
NAMESPACE="$2"

kubectl --namespace ${NAMESPACE} delete sa ${SERVICE_ACCOUNT_NAME};
kubectl --namespace ${NAMESPACE} delete clusterrolebinding ${SERVICE_ACCOUNT_NAME}-binding