#!/bin/bash
#set -e
set -o pipefail

# Add user to k8s using service account, no RBAC (must create RBAC after this script)
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
 echo "usage: $0 <service_account_name> <namespace>"
 exit 1
fi

SERVICE_ACCOUNT_NAME=$1
NAMESPACE="$2"

if [[ $OSTYPE =~ .*darwin.* ]]; then
  TARGET_FOLDER="/Users/${USER}/.kube/config-${NAMESPACE}-${SERVICE_ACCOUNT_NAME}"
elif [[ $OSTYPE =~ .*linux.* ]]; then
  TARGET_FOLDER="/home/${USER}/.kube/config-${NAMESPACE}-${SERVICE_ACCOUNT_NAME}"
fi

KUBECFG_FILE_NAME="k8s-${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-conf.yaml"
KUBECFG_FILE_PATH="${TARGET_FOLDER}/${KUBECFG_FILE_NAME}"
CA_FILE_PATH="${TARGET_FOLDER}/ca.crt"

create_target_folder() {
    echo -n "Creating target directory to hold files in ${TARGET_FOLDER}..."
    mkdir -p "${TARGET_FOLDER}"
    printf "done"
}

create_service_account() {
    echo -e "\\nCreating a service account: ${SERVICE_ACCOUNT_NAME} on namespace: ${NAMESPACE}"
    kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}"
}

create_cluster_role_binding() {
    echo -e "\\nCreating a cluster role binding for account: ${SERVICE_ACCOUNT_NAME} on namespace: ${NAMESPACE}"
    kubectl create clusterrolebinding "${SERVICE_ACCOUNT_NAME}-binding" --clusterrole=admin --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
}

get_secret_name_from_service_account() {
    echo -e "\\nGetting secret of service account ${SERVICE_ACCOUNT_NAME}-${NAMESPACE}"
    SECRET_NAME=$(kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}" -o json | jq -r '.secrets[].name')
    echo "Secret name: ${SECRET_NAME}"
}

extract_ca_crt_from_secret() {
    echo -e -n "\\nExtracting ca.crt from secret..."
    kubectl get secret "${SECRET_NAME}" --namespace "${NAMESPACE}" -o json | jq \
    -r '.data["ca.crt"]' | base64 -D > "${CA_FILE_PATH}"
    printf "done"
}

get_user_token_from_secret() {
    echo -e -n "\\nGetting user token from secret..."
    USER_TOKEN=$(kubectl get secret "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" -o json | jq -r '.data["token"]' | base64 -D)
    printf "done"
}

set_kube_config_values() {
    context=$(kubectl config current-context)
    echo -e "\\nSetting current context to: $context"

    CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
    echo "Cluster name: ${CLUSTER_NAME}"

    ENDPOINT=$(kubectl config view \
    -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
    echo "Endpoint: ${ENDPOINT}"

    # Set up the config
    echo -e "\\nPreparing k8s-${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-conf"
    echo -n "Setting a cluster entry in kubeconfig..."
    kubectl config set-cluster "${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_PATH}" \
    --server="${ENDPOINT}" \
    --certificate-authority="${CA_FILE_PATH}" \
    --embed-certs=true

    echo -n "Setting token credentials entry in kubeconfig..."
    kubectl config set-credentials \
    "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_PATH}" \
    --token="${USER_TOKEN}"

    echo -n "Setting a context entry in kubeconfig..."
    kubectl config set-context \
    "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_PATH}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --namespace="${NAMESPACE}"

    echo -n "Setting the current-context in the kubeconfig file..."
    kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_PATH}"
}


create_target_folder
create_service_account
create_cluster_role_binding
get_secret_name_from_service_account
extract_ca_crt_from_secret
get_user_token_from_secret
set_kube_config_values

echo -e "\\nAll done! Test with:"
echo "export KUBECONFIG=${KUBECFG_FILE_PATH}"
echo "kubectl get pods"
KUBECONFIG=${KUBECFG_FILE_PATH} kubectl get pods