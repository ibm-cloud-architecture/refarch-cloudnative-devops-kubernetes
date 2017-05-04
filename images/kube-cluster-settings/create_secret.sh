#!/bin/bash
set -x

# Replace API Key
string_to_replace=$(yaml read secret.yaml data.api-key)
sed -i.bak s%${string_to_replace}%${BLUEMIX_API_KEY}%g secret.yaml

secret=$(kubectl get secrets | grep bluemix-api-key | awk '{print $1}' | head -1)

if [[ -z "${secret// }" ]]; then
    echo "Creating secret"
	kubectl create -f secret.yaml
else
    echo "Updating secret"
	kubectl apply -f secret.yaml
fi