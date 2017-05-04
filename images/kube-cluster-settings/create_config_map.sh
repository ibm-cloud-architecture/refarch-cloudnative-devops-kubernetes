#!/bin/bash
set -x

# Replace Bluemix API Endpoint
string_to_replace=$(yaml read config.yaml data.bluemix-api-endpoint)
sed -i.bak s%${string_to_replace}%${BLUEMIX_API_ENDPOINT}%g config.yaml

# Replace Bluemix Org
string_to_replace=$(yaml read config.yaml data.bluemix-org)
sed -i.bak s%${string_to_replace}%${BLUEMIX_ORG}%g config.yaml

# Replace Bluemix Space
string_to_replace=$(yaml read config.yaml data.bluemix-space)
sed -i.bak s%${string_to_replace}%${BLUEMIX_SPACE}%g config.yaml

# Replace Bluemix Registry
string_to_replace=$(yaml read config.yaml data.bluemix-registry)
sed -i.bak s%${string_to_replace}%${BLUEMIX_REGISTRY}%g config.yaml

# Replace Bluemix Registry Namespace
string_to_replace=$(yaml read config.yaml data.bluemix-registry-namespace)
sed -i.bak s%${string_to_replace}%${BLUEMIX_REGISTRY_NAMESPACE}%g config.yaml

# Replace Kubernetes Cluster Name
string_to_replace=$(yaml read config.yaml data.kube-cluster-name)
sed -i.bak s%${string_to_replace}%${KUBE_CLUSTER_NAME}%g config.yaml

config=$(kubectl get configmaps | grep bluemix-target | awk '{print $1}' | head -1)

if [[ -z "${config// }" ]]; then
    echo "Creating configmap"
	kubectl create -f config.yaml
else
    echo "Updating configmap"
	kubectl apply -f config.yaml
fi