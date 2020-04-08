## Install Tekton Pipeline, Dashboard and Webhook extension

1. Install [Tekton Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/install.md):
```
  # Create a new project called `tekton-pipelines`
  oc new-project tekton-pipelines

  # The `tekton-pipelines-controller` service account needs the `anyuid` security context constraint in order to run the webhook pod.  
  oc adm policy add-scc-to-user anyuid -z tekton-pipelines-controller

  # Install latest version of Tekton Pipelines
  oc apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
```

To access the docker registry, create the required secret as follows.

Create the environment variables to be use, replace with real values and include the single quotes:

export DOCKER_USERNAME='<DOCKER_USERNAME>'

export DOCKER_PASSWORD='<DOCKER_PASSWORD>'

export DOCKER_EMAIL='<DOCKER_EMAIL>'

kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=${DOCKER_USERNAME} \
  --docker-password=${DOCKER_PASSWORD} \
  --docker-email=${DOCKER_EMAIL} \
  -n ${NAMESPACE}

Before creating, replace the values as mentioned above. Note: If your docker password contains special characters in it, please enclose the password in double quotes or place an escape character before each special character.

(Optional) Only if you have problems with the credentials you can recreate it, but you have to deleted first

kubectl delete secret regcred -n $NAMESPACE

- Create a pipeline-account service account, role and rolebinding:

oc apply -f pipeline-account.yaml

- Update the pipeline-account service account with the image pull secret created.

# Patch the default service account with the image pull secret
oc patch serviceaccount/pipeline-account --type='json' -p='[{"op":"add","path":"/imagePullSecrets/-","value":{"name":"regcred"}}]'

Create a clusteradmin rolebinding for the pipeline-account. NOTE: This should not be done in production and the service account should only be set with permissions required to update deployment resource.

# Create clusteradmin rolebinding
oc apply -f clusteradmin-rolebinding.yaml

Create the Task resources.
# Create the build task
oc apply -f Tasks/source-to-image-inventory.yaml
# Create the deploy task
oc apply -f Tasks/deploy-using-kubectl-inventory.yaml
