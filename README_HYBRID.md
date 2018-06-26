# Hybrid Cloud DevOps
Use hosted Jenkins to build and deploy containers to multiple clouds.

## Table of Contents
* [Overview](#overview)
* [Requirements:](#requirements)
* [Installing bluecompute-ce charts](#installing-bluecompute-ce-charts)
* [Docker Registry Setup](#docker-registry-setup)
	+ [Create a Registry Namespace](#create-a-registry-namespace)
	+ [Create Docker Registry Token](#create-docker-registry-token)
	+ [Upload the Docker Token to Jenkins](#upload-the-docker-token-to-jenkins)
	+ [Create Docker Registry Secret](#create-docker-registry-secret)
* [Setup Service Accounts](#setup-service-accounts)
* [Setting Up IKS & ICP Cluster Access in Jenkins](#setting-up-iks--icp-cluster-access-in-jenkins)
	+ [Setting up IKS Cluster Access in Jenkins](#setting-up-iks-cluster-access-in-jenkins)
		- [Get the IKS CA Certificate and the Token](#get-the-iks-ca-certificate-and-the-token)
		- [Upload the IKS CA Certificate to Jenkins](#upload-the-iks-ca-certificate-to-jenkins)
		- [Upload the IKS Token to Jenkins](#upload-the-iks-token-to-jenkins)
	+ [Setting up ICP Cluster Access in Jenkins](#setting-up-icp-cluster-access-in-jenkins)
		- [Get the ICP CA Certificate and the Token](#get-the-icp-ca-certificate-and-the-token)
		- [Upload the ICP CA Certificate and the Token to Jenkins](#upload-the-icp-ca-certificate-and-the-token-to-jenkins)
* [Setting up the Pipelines](#setting-up-the-pipelines)
	+ [Setup the Build Pipeline](#setup-the-build-pipeline)
	+ [Setup the IKS Deploy Pipeline](#setup-the-iks-deploy-pipeline)
	+ [Setup the ICP Deploy Pipeline](#setup-the-icp-deploy-pipeline)
* [Run the pipelines](#run-the-pipelines)
	+ [Run the Build Pipeline](#run-the-build-pipeline)
	+ [Run the IKS Deploy Pipeline](#run-the-iks-deploy-pipeline)
	+ [Run the ICP Deploy Pipeline](#run-the-icp-deploy-pipeline)

## Overview
When adopting new technologies, like Kubernetes, most companies want to be able to integrate them with their existing toolchain. For example, most companies who use their own hosted Jenkins as their CI/CD server also expect to be able to use it for CI/CD on Kubernetes.

Given the many Jenkins and Application environment configurations (on-premise, public, hybrid, etc) there is a need for a streamlined approach for CI/CD that works in any configuration. Fortunately, Kubernetes and the many projects that support it (docker, helm, etc) provide a standard approach that, though it can change implementation-wise, can work across the different environment configurations.

In this document, we will explain how you can you use a self-hosted `Jenkins` instance and a `Docker` repository to put together and run CI/CD pipelines to deploy updates to applications that are deployed across 2 separate Kubernetes clusters. More specifically, we are going to deploy to an [`IBM Cloud Kubernetes Service`](https://www.ibm.com/cloud/container-service)(IKS) cluster and to a [`IBM Cloud Private`](https://www.ibm.com/cloud/private)(ICP) cluster.

A common use case is to use the public IKS cluster as a Development environment, whereas the ICP cluster would serve as the Production cluster behind a firewall.

![Diagram](static/imgs/jenkins-hybrid.png?raw=true)

**NOTE:** It is a best practice to separate build and deploy by using separate clusters. So the ideal architecture would be something like the following:
* 1 Jenkins deployment.
	+ Will trigger build pipelines on the ICP build cluster.
	+ Will trigger deploy pipelines on the ICP production cluster.
	+ Will run deploy pipelines locally and deploy to IKS.
* 1 ICP cluster to run the build pipelines.
* 1 ICP cluster to run ICP deploy pipelines and Production workloads.
* 1 IKS cluster to run dev workloads.

## Requirements:
* Install the following CLI's on your laptop/workstation:
	+ [`ibmcloud`](https://console.bluemix.net/docs/cli/reference/bluemix_cli/get_started.html#getting-started)
	+ [`docker`](https://docs.docker.com/install/)
	+ [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
	+ [`helm`](https://docs.helm.sh/using_helm/#installing-helm)
* A running Jenkins instance.
	+ Use these download [instructions](https://jenkins.io/download/)
* Install the following Jenkins plugins:
    + [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes):
    	- kubernetes:1.8.2
    + [Pipeline](https://plugins.jenkins.io/workflow-aggregator)
    	- workflow-aggregator:2.5
    + [Pipeline: Job](https://plugins.jenkins.io/workflow-job)
    	- workflow-job:2.21
    + [Credentials Binding Plugin](https://plugins.jenkins.io/credentials-binding)
	    - credentials-binding:1.16
    + [Git Plugin](https://plugins.jenkins.io/git)
    	- git:3.9.1
    + [Rebuilder](https://plugins.jenkins.io/rebuild)
    	- rebuilder:1.28
	+ **NOTE:**
		- The above are the plugin versions at the time of this writing.
		- Please note that you may be required to update the plugin versions so that everything works properly.
* Install the [`kubectl CLI`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) on your Jenkis host.
* An [IBM Cloud Account](https://console.bluemix.net/registration/).
	+ Needed for the IKS cluster and the Containter Registry Service.
* An [IBM Cloud Container Service Cluster](https://console.bluemix.net/containers-kubernetes/catalog/cluster/create).
	+ There is an option for a FREE cluster.
* An [IBM Cloud Private Cluster](https://github.com/IBM/deploy-ibm-cloud-private).
	+ For more install options, check out this [document](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html).

## Installing bluecompute-ce charts
This document assumes you have already installed the `helm` charts for our microservices reference architecture app, which is known as `bluecompute-ce`. To learn about the app's architecture, checkout it's repo [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#introduction).

* To install the chart on IKS, checkout the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-bluecompute-to-ibm-cloud-container-service).
	+ To access the `bluecompute-web` front end, follow these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#access-and-validate-the-application).
* To install the chart on ICP, checkout the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-bluecompute-to-ibm-cloud-private).
	+ To access the `bluecompute-web` front end, follow these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#access-and-validate-the-application-1).

If you want to checkout the umbrella chart for `bluecompute-ce`, check it out [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/master/bluecompute-ce).

Lastly, if you want to checkout the individual project's code and charts, checkout this link [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#project-repositories).

## Docker Registry Setup
For this guide, we are going to use the `IBM Cloud Container Registry` service to host our docker images. With an IBM Cloud account, you have access to a generous FREE tier. To do the initial setup, we recommend you follow their [Registry Quick Start](https://console.bluemix.net/containers-kubernetes/registry/start) guide, in which you will setup the required CLI components and push your first image to the registry!

Now that your registry is setup we can proceed to creating a `Registry Token`, which will be used by the Jenkins pipeline to push and pull images from the registry. This token can be made non-expiring, which is ideal for CI/CD servers that run 24/7. Also, this token is not tied to a user account, so no need to constanly enter username and passwords manually to login into docker registry.

### Create a Registry Namespace
In order to push Docker images to the IBMCloud Container Registry, you will first need to create a globally unique namespace:
```bash
$ bx cr namespace-add ${NAMESPACE}
```

Where `${NAMESPACE}` is the globally unique name for your namespace.

### Create Docker Registry Token
To create a Registry Token on , run the following command:
```bash
$ bx cr token-add --non-expiring --readwrite --description "For Hybrid Deployment"
```

### Upload the Docker Token to Jenkins
For Jenkins to be able to use the Docker Registry Token, we must create a `Username with password` credentials in Jenkins. To do so, open a browser windows and do the following:
* Enter the URL to your jenkins instance and go to `Jenkins->Credentials->System->Global credentials (unrestricted)`
	+ Or you can use the following URL:
	+ `http://JENKINS_IP:PORT/credentials/store/system/domain/_/`
* Click on `Add Credentials`
	+ Or you can use the following URL:
	+ `http://JENKINS_IP:PORT/credentials/store/system/domain/_/newCredentials`
* Create `Username with password` credentials for the token:
	+ Select `Username with password` as the kind.
	+ Make sure the `Scope` stays as `Global`.
	+ Enter `token` as the `Username`.
		+ When doing `docker login`, this is the username associated with the token.
	+ Enter the token that you obtained in the previous step as the `Password`.
	+ Enter `registry-credentials` as the `ID`.
	+ Optional: Enter a description for the secret file.
	+ Press the `OK` button.
+ If successful, you should see the `token/******` credentials entry listed.

### Create Docker Registry Secret
On both IKS and ICP clusters, create the following Docker Config secret using the token from previous step:
```bash
# Create jenkins namespace
$ kubectl create ns jenkins

# Create docker registry secret
$ kubectl --namespace jenkins create secret docker-registry bluemix-registry --docker-server=registry.ng.bluemix.net --docker-username=token --docker-password=${TOKEN} --docker-email=test@test.com
```

Where:
* `jenkins` is the namespace in which we are going to store this secret.
* `bluemix-registry` is the name of the secret.
* `registry.ng.bluemix.net` is the registry domain address.
* `token` is the username associated with the registry token.
* `${TOKEN}` is the actual token obtained in the previous step.
* `test@test.com` is just a sample email to associate with the token.

**NOTE:** Please do this on both IKS and ICP clusters as they BOTH need this secret.

Now our docker registry is ready to be used by the clusters and the pipelines.

## Setup Service Accounts
In order for clusters to be able to deploy pods from our registry, we need to create a [Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) on each cluster and associate the docker registry secret, known as a [Pull Down Secret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) to it. This is so that the service account is able to pull down images from the registry and deploy pods with them. To do so, run the following commands in BOTH IKS and ICP clusters:
```bash
# Create service account
$ kubectl create serviceaccount jenkins --namespace jenkins

# Assign admin cluster role to service account so it can get/create/update/delete pods
# NOTE: In production it is a best practice to assign a non-admin role with less priviledges
$ kubectl create clusterrolebinding jenkins-admin --clusterrole=admin --serviceaccount=jenkins:jenkins

# Patch the service account with the registry secret
$ kubectl --namespace jenkins patch serviceaccount jenkins -p '{"imagePullSecrets": [{"name": "bluemix-registry"}]}'
```

**NOTE:** Please run the above commands in BOTH IKS and ICP clusters.

Now both clusters have access to the docker registry and its docker images to deploy pods with them.

## Setting Up IKS & ICP Cluster Access in Jenkins
Ok, now we are getting to an interesting point in this guide. There are many ways in which we can configure access to Jenkins to access the clusters. There are also many network access variables to take into account. To simplify things while still showing different networking scenarios, we are going to assume the folloging:
* Jenkins host is running behind a VPN with NAT (internet) access.
	+ Jenkins has direct networking access to ICP cluster.
	+ Jenkins has direct networking access to IKS cluster, but not the other way around.
* ICP cluster is running behind the same VPN with NAT access.
	+ ICP cluster has direct networking access to Jenkins host.
* IKS cluster is running in the public cloud.
	+ IKS cluster has no direct access to Jenkins host.

Perhaps these relationships are better shown by revisiting the architecture diagram:

![Diagram](static/imgs/jenkins-hybrid.png?raw=true)

The above network configuration influences the way in which we configure both cluster access and the way we run pipelines. For example:

* In the Jenkins-ICP scenario, we can leverage the [`Kubernetes Plugin`](https://github.com/jenkinsci/kubernetes-plugin) to run pipelines in Jenkins slave pods that run directly on ICP and report job status back to Jenkins. The bidirectional network access allows for this scenario to be possible.
* In the Jenkins-IKS scenario, since there is only a one-way direct network access between Jenkins and IKS, we cannot leverage the `Kubernetes Plugin` to deploy and run pipelines. However, we can still leverage the ['Pipeline Plugin'](https://plugins.jenkins.io/workflow-aggregator) to run pipelines that deploy updates to IKS cluster directly from the Jenkins host.

Both approaches require the same configuration (setting up cluster access on `kubectl`) with a slightly different implementation that depends on the Jenkins plugin we use.

### Setting up IKS Cluster Access in Jenkins
First let's setup access to the IKS cluster in Jenkins. To do so, we are going to do the following:
* Get the service account Certificate of Authority.
* Save the Certificate as a Jenkins secret file.
* Get the service account token.
* Save the token as a Jenkins secret text.

#### Get the IKS CA Certificate and the Token
Here is how to get CA certificate and the token
```bash
# Get secret name for jenkins service account certificate and token
$ kubectl --namespace jenkins get serviceaccount jenkins -o=jsonpath='{.secrets[0].name}'

# Get certificate of authority from secret jenkins-token-t8fkk
$ kubectl --namespace jenkins get secret ${SECRET_NAME} -o=jsonpath='{.data.ca\.crt}' | base64 --decode > iks-ca.crt

# Get token from secret
$ kubectl --namespace jenkins get secret ${SECRET_NAME} -o=jsonpath='{.data.token}' | base64 --decode > iks-token
```
Where `${SECRET_NAME}` is the secret name, which is the result for the first command.

#### Upload the IKS CA Certificate to Jenkins
Now open a browser windows and do the following:
* Enter the URL to your jenkins instance and go to `Jenkins->Credentials->System->Global credentials (unrestricted)`
	+ Or you can use the following URL:
	+ `http://JENKINS_IP:PORT/credentials/store/system/domain/_/`
* Click on `Add Credentials`
	+ Or you can use the following URL
	+ `http://JENKINS_IP:PORT/credentials/store/system/domain/_/newCredentials`
* Create a Secret File for the CA certificate:
	+ Select `Secret file` as the kind.
	+ Make sure the `Scope` stays as `Global`.
	+ Click the `Choose File` button and select the `iks-ca.crt` file you created earlier and upload it.
	+ Enter `iks-ca` as the `ID`.
	+ Optional: Enter a description for the secret file
	+ Press the `OK` button.
+ If successful, you should see the `iks-ca.crt` Secret file entry listed.
	 
#### Upload the IKS Token to Jenkins
Now let's upload the token as a `Secret text` as follows:
* On your browser, go to `http://JENKINS_IP:PORT/credentials/store/system/domain/_/newCredentials`
* Create Secret Text for the Service Token:
	+ Select `Secret text` as the kind.
	+ Make sure the `Scope` stays as `Global`.
	+ In `Secret` enter the contents of the `iks-token` file you created earlier.
	+ Enter `iks-token` as the `ID`.
	+ Optional: Enter a description for the secret text
	+ Press the `OK` button.
+ If successful, you should see the `iks-token` Secret text entry listed.

Now Jenkins has all it needs to access the IKS cluster.

### Setting up ICP Cluster Access in Jenkins
Now let's do the same, but for the ICP cluster. Again, since we will be using the `Kubernetes Plugin` to run the Pipelines on ICP pods, the steps for connecting to the cluster will vary slightly. But essentially we are doing the same thing, which is to get the ICP CA certificate and the service account token and storying it in Jenkins.

#### Get the ICP CA Certificate and the Token
For this step, you can follow the same instructions in [Get the IKS CA Certificate and the Token](#get-the-iks-ca-certificate-and-the-token), but make sure to name the CA certificate as `icp-ca.crt` and the token file as `icp-token`.

#### Upload the ICP CA Certificate and the Token to Jenkins
For ICP we are going to have to do this in `Kubernetes` section of the Jenkins Configuration page. Open a web browser tab and go to `http://JENKINS_IP:PORT/configure`. Assuming you properly installed the `Kubernetes Plugin`, you should now have a `Cloud` section on this page. If you don't, then click on the `Add a new cloud` button that's at the bottom and select the `Kubernetes` option. 

The best way to enter the required information is in 2 parts:
* Fill out the `Cloud` section.
	+ Basically, the ICP URL and access credentials (CA Certificate and Service Account Token).
* Fill out the `Kubernetes Pod Template` section.
	+ This defines the base Jenkins slave pod that will run in ICP and execute the pipelines.
	+ It also specifies how the slave pod communicates back to the Jenkins host.

Now, let's show you some pictures to make this easier. The follwing picture explains how to fill out the `Cloud` section. Once you are done, click the `Test Connection` button (as shown below) to make sure that everything was setup properly and that Jenkins can talk to the ICP cluster.
![Application Architecture](static/imgs/jenkins_cloud.png?raw=true)

The following picture shows you how to fill out the `Kubernetes Pod Template` section, which is at the bottom of the `Cloud` section. If you don't see one listed, then you have to click the `Add Pod Template` button and select the `Kubernetes Pod Template` option. Also, if you don't see the `Container Template` section inside the `Kubernetes Pod Template`, click on the `Add Container` button and select `Container Template` option. Lastly, if you don't see the `Enviroment Variable` section in the `Container Template` section, then click on the `Add Environment Variable` button and select `Environment Variable` option.

![Application Architecture](static/imgs/jenkins_pod_template.png?raw=true)

Once you are done, make sure to click the blue `Save` buttom at the bottom of the page.

Now your Jenkins host is ready to run pipelines!

## Setting up the Pipelines
Now that our Jenkins host is setup with access to both IKS and ICP clusters, it's time to setup the pipelines that it will run. In this guide, we are going to setup 3 separate pipelines:
* 1 build pipeline.
* 1 deploy to IKS pipeline.
* 1 deploy to ICP pipeline.

For this particular case, we are going to run pipelines that will update the [`bluecompute-web`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/master) frontend web app microservice of the reference architecture app.

### Setup the Build Pipeline
To setup this pipeline, click the `New Item` button on your Jenkin's home page or go to this URL: `http://JENKINS_IP:PORT/view/all/newJob`.

Now create a new Pipeline job as shown below:

![Create Pipeline](static/imgs/p_1_create_pipeline.png?raw=true)

The next step is to create the pipeline parameters. You will need the following parameters with their respective default values:
* `CLOUD`: `kubernetes`.
* `NAMESPACE`: `Jenkins`.
* `REGISTRY`: `registry.ng.bluemix.net/REGISTRY_NAMESPACE`.
	+ Where `REGISTRY_NAMESPACE` is the registry namespace you created in the [Create a Registry Namespace](#create-a-registry-namespace) step.
	+ **NOTE:** This is not the same `Jenkins` Kubernetes namespace mentioned just above.
* `SERVICE_ACCOUNT`: `jenkins`.
* `REGISTRY_CREDENTIALS`: `registry-credentials`.
	+ Where `registry-credentials` is the Jenkins credentials that you created for the registry in [Upload the Docker Token to Jenkins](#upload-the-docker-token-to-jenkins).

To create a parameter in Jenkins, just follow the instructions below:
![Create Pipeline](static/imgs/p_2_parameters.png?raw=true)

Once you create a parameter, then fill in the details as shown below:
![Create Pipeline](static/imgs/p_2_parameters_2.png?raw=true)

Do the above for all 5 parameters. 

Now scroll down to the **Pipeline** section and do the following:
* In the `Definition` field, select `Pipeline script from SCM`.
* In the `SCM` field, select `Git`.
* In the `Repository ULR` field, enter `https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web.git`
* In the `Branches to build` field, enter `*/master`.
* In the `Script Path`, enter `JenkinsfileBuildPush`.

Here is a visual guide:
![Create Pipeline](static/imgs/p_3_script.png?raw=true)

Once you do the above, press the `Save` button. You have successfully setup your Build pipeline.

### Setup the IKS Deploy Pipeline
Again, the pipeline setup is similar to the Build pipeline with some minor adjustments. First, create a new Pipeline job and name it `deploy_iks`, then enter the following parameters:
* `CERT_AUTH_ID`: `iks-ca`.
* `IMAGE_PULL_SECRET`: `bluemix-registry`.
* `NAMESPACE`: `jenkins`.
* `REGISTRY`: `registry.ng.bluemix.net/${REGISTRY_NAMESPACE}`.
	+ Where `${REGISTRY_NAMESPACE}` is the registry namespace you created in the [Create a Registry Namespace](#create-a-registry-namespace) step.
	+ **NOTE:** This is not the same `Jenkins` Kubernetes namespace mentioned just above.
* `SERVER_URL`: `${IKS_URL}`.
	+ Where `${IKS_URL}` is the Kubernetes API server URL that you obtain after downloading the cluster context on your workstation as shown in the `Configuring the CLI to run kubectl` section on this [page](https://console.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install).
	+ To obtain the server url directly from `kubectl`, run this command:
		```bash
		$ kubectl config view | grep server
		```
	+ Another option is to open the config file directly, run this command:
		```bash
		# Open the config file directly
		$ cat ~/.bluemix/plugins/container-service/clusters/${CLUSTER_NAME}/kube-config-${CLUSTER_NAME}.yml | grep server
		# Using environment variable
		$ cat ${KUBECONFIG} | grep server
		```
* `SERVICE_ACCOUNT`: `jenkins`.
* `TOKEN_ID`: `iks-token`.
* `IMAGE_TAG`: `latest`.

The repo setup is the same the previous step with the following change:
* In the `Script Path`, enter `JenkinsfileDeployLocal`.

Once you do the above, press the `Save` button. You have successfully setup your IKS deploy pipeline.

### Setup the ICP Deploy Pipeline
Again, the pipeline setup is similar to the Build pipeline with some minor adjustments. First, create a new Pipeline job and name it `deploy_icp`, then enter the following parameters:
* `CLOUD`: `kubernetes`.
* `IMAGE_PULL_SECRET`: `bluemix-registry`.
* `NAMESPACE`: `jenkins`.
* `REGISTRY`: `registry.ng.bluemix.net/${REGISTRY_NAMESPACE}`.
	+ Where `${REGISTRY_NAMESPACE}` is the registry namespace you created in the [Create a Registry Namespace](#create-a-registry-namespace) step.
	+ **NOTE:** This is not the same `Jenkins` Kubernetes namespace mentioned just above.
* `SERVICE_ACCOUNT`: `jenkins`.
* `IMAGE_TAG`: `latest`.

The repo setup is the same the previous step with the following change:
* In the `Script Path`, enter `JenkinsfileDeploy`.

Once you do the above, press the `Save` button. You have successfully setup your ICP deploy pipeline.

## Run the pipelines
Finally! Now comes the part where we run the pipelines. Assuming everything was setup properly, running the pipelines should be done in the following order:
* Run the Build Pipeline.
* Run the IKS Deploy Pipeline with the image tag (i.e. build number) produced by the Build Pipeline.
* Run the ICP Deploy Pipeline with the image tag (i.e. build number) produced by the Build Pipeline.

### Run the Build Pipeline
This pipeline will run 2 steps:
1. Build the docker image.
2. Push the docker image to the Docker registry in IBM Cloud.

This pipeline will take advantage of the `Kubernetes Plugin` and run as a pod inside of the ICP cluster. For more details on the pipeline itself, checkout the code [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/JenkinsfileBuildPush).

To run the pipeline, open the `build_pipeline` and start it as follows:
![Run Pipeline](static/imgs/rp_1_run_pipeline.png?raw=true)

To check build progress, open the the build console output as follows:
![Pipeline Output](static/imgs/rp_2_progress.png?raw=true)

Notice the output of the individual pipelines, mostl the `docker build` and `docker push` logs.

To check if the pipeline finished successfully, check for the `Finished: SUCCESS` log at the end:
![Pipeline Success](static/imgs/rp_3_success.png?raw=true)

The resulting image tag will be the build number as shown above. This image tag will be used by the Deploy pipelines to update the deployments.

### Run the IKS Deploy Pipeline
This pipeline just runs one stage, which is to update the container image from the pod in the existing `bluecompute-web` deployment.

Since this pipeline won't be leveraging the `Kubernetes Plugin`, it will run the pipeline from the local Jenkins slaves. For more details on the pipeline itself, checkout the code [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/JenkinsfileDeployLocal).

To run the pipeline, just open the `deploy_iks` pipeline job and click on the `Build with Parameters` button. Then, on the `IMAGE_TAG` field enter the Build Pipeline's last successful build number. i.e. if the last build number was `#13`, then just enter `13`.

Follow the same procedure to get the job's console output as explained in the previous step.
![Deploy Success](static/imgs/rp_4_deploy.png?raw=true)

To verify that the pipeline indeed updated the docker image, run the following command:
```bash
$ kubectl --namespace jenkins get deployments bluecompute-web -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

If successful, you should see the docker image printed as follows:
```bash
registry.ng.bluemix.net/jenkins-fabio/jenkins/bluecompute-ce-web:${IMAGE_TAG}
```

Where `${IMAGE_TAG}` is the image tag that you entered right before running the deploy pipeline.

Lastly, verify that you can access the web front end by following these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#access-and-validate-the-application)

If you can access the web app, then you have successfully ran the deploy pipeline! 

### Run the ICP Deploy Pipeline
This pipeline just runs one stage, which is to update the container image from the pod in the existing `bluecompute-web` deployment.

This pipeline will take advantage of the `Kubernetes Plugin` and run as a pod inside of the ICP cluster. For more details on the pipeline itself, checkout the code [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/JenkinsfileDeploy).

To run the pipeline, just open the `deploy_icp` pipeline job and click on the `Build with Parameters` button. Then, on the `IMAGE_TAG` field enter the Build Pipeline's last successful build number. i.e. if the last build number was `#13`, then just enter `13`.

Follow the same procedure to get the job's console output as explained in the previous step.
![Deploy Success](static/imgs/rp_4_deploy.png?raw=true)

To verify that the pipeline indeed updated the docker image, run the following command:
```bash
$ kubectl --namespace jenkins get deployments bluecompute-web -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

If successful, you should see the docker image printed as follows:
```bash
registry.ng.bluemix.net/jenkins-fabio/jenkins/bluecompute-ce-web:${IMAGE_TAG}
```

Where `${IMAGE_TAG}` is the image tag that you entered right before running the deploy pipeline.

Lastly, verify that you can access the web front end by following these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#access-and-validate-the-application-1)

If you can access the web app, then you have successfully ran the deploy pipeline! 