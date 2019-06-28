# DevOps for Cloud Native Reference Application

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring*

## Table of Contents
- [DevOps for Cloud Native Reference Application](#devops-for-cloud-native-reference-application)
  * [Table of Contents](#table-of-contents)
  * [Introduction](#introduction)
  * [Architecture & CI/CD Workflow](#architecture--cicd-workflow)
  * [Pre-Requisites](#pre-requisites)
    + [Download required CLIs](#download-required-clis)
    + [Create a Kubernetes Cluster](#create-a-kubernetes-cluster)
    + [Install Bluecompute Reference Architecture Chart](#install-bluecompute-reference-architecture-chart)
  * [Deploy Jenkins to Kubernetes Cluster](#deploy-jenkins-to-kubernetes-cluster)
    + [Pre-Requisites:](#pre-requisites)
      - [IBM Cloud Private: Image Policy](#ibm-cloud-private-image-policy)
      - [Optional: IBM Cloud Kubernetes Service - Create a Persistent Volume Claim](#optional-ibm-cloud-kubernetes-service---create-a-persistent-volume-claim)
      - [Optional: IBM Cloud Private - Dynamic Provisioning](#optional-ibm-cloud-private---dynamic-provisioning)
    + [1. Initialize `helm` in your cluster:](#1-initialize-helm-in-your-cluster)
      - [IBM Cloud Kubernetes Service](#ibm-cloud-kubernetes-service)
      - [IBM Cloud Private](#ibm-cloud-private)
    + [2. Install Jenkins Chart:](#2-install-jenkins-chart)
      - [Install the Jenkins Chart and Provision a PVC dynamically](#install-the-jenkins-chart-and-provision-a-pvc-dynamically)
      - [Install the Jenkins Chart and Pass an Existing PVC](#install-the-jenkins-chart-and-pass-an-existing-pvc)
      - [Install the Jenkins Chart without a PVC](#install-the-jenkins-chart-without-a-pvc)
    + [3. Validate Jenkins Deployment](#3-validate-jenkins-deployment)
      - [1. Obtain Jenkins `admin` password:](#1-obtain-jenkins-admin-password)
      - [2. Obtain Jenkins URL:](#2-obtain-jenkins-url)
        * [2.a. Minikube Deployment](#2a-minikube-deployment)
        * [2.b. IBM Cloud Kubernetes Service](#2b-ibm-cloud-kubernetes-service)
        * [2.c. IBM Cloud Private](#2c-ibm-cloud-private)
      - [3. Login to Jenkins URL](#3-login-to-jenkins-url)
      - [4. Increase Container Cap Count](#4-increase-container-cap-count)
    + [Delete Jenkins Deployment](#delete-jenkins-deployment)
  * [Setup Docker Registry](#setup-docker-registry)
    + [Step 1: Create Docker Secret](#step-1-create-docker-secret)
      - [DockerHub](#dockerhub)
      - [IBM Cloud Kubernetes Service](#ibm-cloud-kubernetes-service-1)
        * [1. Create a Registry Namespace](#1-create-a-registry-namespace)
        * [2. Create Docker Registry Token](#2-create-docker-registry-token)
        * [3. Create Docker Secret](#3-create-docker-secret)
      - [IBM Cloud Private](#ibm-cloud-private-1)
    + [Step 2: Patch Jenkins Service Account](#step-2-patch-jenkins-service-account)
    + [Step 3: Save Docker Credentials in Jenkins](#step-3-save-docker-credentials-in-jenkins)
  * [Create and Run a Sample CI/CD Pipeline](#create-and-run-a-sample-cicd-pipeline)
    + [Step 1: Create a Sample Job](#step-1-create-a-sample-job)
    + [Step 2: Select Pipeline Type](#step-2-select-pipeline-type)
    + [Step 3: Setup Sample Pipeline](#step-3-setup-sample-pipeline)
    + [Step 4: Launch Pipeline Build](#step-4-launch-pipeline-build)
    + [Step 5: Open Pipeline Console Output](#step-5-open-pipeline-console-output)
    + [Step 6: Monitor Console Output](#step-6-monitor-console-output)
  * [Conclusion](#conclusion)
  * [Further Reading: Hybrid Cloud Setup](#further-reading-hybrid-cloud-setup)
  * [Further Reading: Using Podman as the CI/CD Container Engine](#further-reading-using-podman-as-the-cicd-container-engine)

## Introduction
DevOps, specifically automated Continuous Integration and Continuous Deployment (CI/CD), is important for Cloud Native Microservice style application. This project is developed to demonstrate how to use tools and services available on IBM Cloud to implement the CI/CD for the BlueCompute reference application.

The project uses the [Jenkins Helm Chart](https://github.com/kubernetes/charts/tree/master/stable/jenkins) to install a Jenkins Master pod with the [Kubernetes Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Kubernetes+Plugin) in a Kubernetes Cluster. [**Helm**](https://github.com/kubernetes/helm) is Kubernetes's package manager, which facilitates deployment of prepackaged Kubernetes resources that are reusable. This setup allows Jenkins to spin up ephemeral pods to run Jenkins jobs and pipelines without the need of Always-On dedicated Jenkins slave/worker servers, which reduces Jenkins's infrastructural costs.

Let's get started.

## Architecture & CI/CD Workflow
Here is the High Level DevOps Architecture Diagram for the Jenkins setup on Kubernetes, along with a typical CI/CD workflow:

![DevOps Toolchain](static/imgs/architecture.png?raw=true)

This guide will install the following resources:
* 1 x 8GB [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC) to Store Jenkins data and builds' information.
    * Be sure that your Kubernetes Cluster can support PVCs size of 8GB
* 1 x Jenkins Master Kubernetes Pod with Kubernetes Plugin Installed.
* 1 x Kubernetes Service for above Jenkins Master Pod with port 8080 exposed to a LoadBalancer.
* All using Kubernetes Resources.

## Pre-Requisites
### Download required CLIs

To deploy the application, you require the following tools:
* [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
* [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
  + If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_helm_cli.html) to install `helm`.
* [IBM Cloud CLI](https://console.bluemix.net/docs/cli/reference/bluemix_cli/get_started.html)
    + Only if you are using an IBM Cloud Kubernetes Service cluster.

### Create a Kubernetes Cluster
The following clusters have been tested with this sample application:
* [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) - Create a single node virtual cluster on your workstation
* [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
* [IBM Cloud Private](https://www.ibm.com/cloud/private) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud private-ce) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html) to install IBM Cloud Private CE.

### Install Bluecompute Reference Architecture Chart
This document assumes that you have installed the `bluecompute-ce` chart in the `default` namespace of your cluster. To install `bluecompute-ce` chart, follow these instructions based on your environment:

* **Minikube:** Use these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-to-kubernetes-cluster).
* **IBM Cloud Kubernetes Service:** Use these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-bluecompute-to-ibm-cloud-container-service).
* **IBM Cloud Private:** Use these [instructions](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-bluecompute-to-ibm-cloud-private).

## Deploy Jenkins to Kubernetes Cluster
As mentioned in the [**Introduction Section**](#introduction), we will be using a [Jenkins Helm Chart](#https://github.com/kubernetes/charts/tree/master/stable/jenkins) to deploy Jenkins into a Kubernetes Cluster. Before you do so, make sure that you installed all the required CLIs as indicated in the [**Pre-Requisites**](#pre-requisites).

### Pre-Requisites:
#### IBM Cloud Private: Image Policy
Starting with version 3.1.0 for IBM Cloud Private, you are REQUIRED to create an [`Image Policy`](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/image_security.html) in order to whitelist container images that come from registries other than the built-in Private Docker Registry. We created a simple `Cluster Image Policy` located at [jenkins/cluster_image_policy.yaml](jenkins/cluster_image_policy.yaml) that lets you deploy not only the Jenkins images but also some images that we built to run the CI/CD environment for this demo.

To create the `Cluster Image Policy`, run the following command:
```bash
kubectl apply -f jenkins/cluster_image_policy.yaml
```

#### Optional: IBM Cloud Kubernetes Service - Create a Persistent Volume Claim
If you would like Jenkins to use a PVC, you must provision a PVC from IBM Cloud and pass it to the `helm install` command once you get to the [Install the Jenkins Chart and Pass an Existing PVC](#install-the-jenkins-chart-and-pass-an-existing-pvc) step.

To create a Persistent Volume Claim (PVC), use the commands below:
```bash
kubectl apply -f jenkins/ibm_cloud_container_service/pvc.yaml
```

**Note:** that the minimum PVC size for IBM Cloud Kubernetes Service is `20GB`.

Before you are able to use your PVC, it needs to be `Bound` to the cluster. To watch for changes in its provisioning status, use the following command:
```bash
kubectl get pvc jenkins-home -o wide -w
NAME           STATUS    VOLUME                                     CAPACITY  ACCESS MODES   STORAGECLASS       AGE
jenkins-home   Pending                                                                       ibmc-file-silver   3s
jenkins-home   Bound     pvc-f62fdc8a-797c-11e8-896e-02c97f163c96   20Gi      RWO            ibmc-file-silver   3m
```

Once see a new entry for `jenkins-home` with a status of `Bound`, it means that the PVC is ready to be used to install the Jenkins Chart.

#### Optional: IBM Cloud Private - Dynamic Provisioning
Though not necessary to install Jenkins chart, we highly recommend that you setup [Dynamic Provisioning](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/manage_cluster/cluster_storage.html) in your ICP cluster so that you can save your Jenkins Data.

### 1. Initialize `helm` in your cluster:
```bash
helm init
```

This initializes the `helm` client as well as the server side component called `tiller`.

#### IBM Cloud Kubernetes Service
For IKS, you need to download your cluster configuration first, setup `KUBECONFIG`, and then you can proceed with `helm init` as follows:
```bash
# Download cluster configuration to your workstation
# Make sure to run the "export KUBECONFIG=" command it spits out in the end
ibmcloud ks cluster-config ${CLUSTER_NAME}

# Init helm in your cluster
helm init
```

#### IBM Cloud Private
If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_helm_cli.html) to install and setup `helm`.

### 2. Install Jenkins Chart:
Each of the following `helm install` options downloads the Jenkins chart from Kubernetes Stable Charts [Repository](https://github.com/kubernetes/charts/tree/master/stable) (which comes by default with helm) and installs it on your cluster.

**IMPORTANT:**
* The Jenkins Master itself takes a few minutes to initialize even after showing installation success. The output of the `helm install` command will provide instructions on how to access the newly installed Jenkins Pod. For more information on the additional options for the chart, see this [document](https://github.com/kubernetes/charts/tree/master/stable/jenkins#configuration).
* For Jenkins to work properly, the chart also installs these [plugins](https://github.com/helm/charts/blob/master/stable/jenkins/values.yaml#L92).
  + Because Jenkins and these plugins get updated regularly, you might be required to update these plugins before you start creating pipelines. To update the plugins, please follow these intructions from the official Jenkins documentation after installing the Jenkins chart.
    - https://jenkins.io/doc/book/managing/plugins/#from-the-web-ui
  + If the Jenkins version that you installed is very outdated, the latest plugin versions might not work at all. This means that you might have to install a chart with the latest supported version of Jenkins before you upgrade the plugins.

#### Install the Jenkins Chart and Provision a PVC dynamically
The following command assumes you have [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) enabled, which will not only install jenkins, but also provision a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) where Jenkins can store its build data:
```bash
helm upgrade --install jenkins --namespace default \
    --set master.serviceType=NodePort \
    --set rbac.create=true \
    stable/jenkins # If ICP, add the --tls flag
```

#### Install the Jenkins Chart and Pass an Existing PVC
To Install the Jenkins Chart and Pass an Existing PVC, use the following command:
```bash
helm upgrade --install jenkins --namespace default \
    --set master.serviceType=NodePort \
    --set rbac.create=true \
    --set persistence.existingClaim=${EXISTING_PVC} \
    stable/jenkins # If ICP, add the --tls flag
```

Where `${EXISTING_PVC}` is the name of an existing PVC, which is usually named `jenkins-home`.

#### Install the Jenkins Chart without a PVC
To Install the Jenkins Chart without a PVC, use the following command:
```bash
helm upgrade --install jenkins --namespace default \
    --set master.serviceType=ClusterIP \
    --set master.ingress.enabled=true \
    --set rbac.create=true \
    --set persistence.enabled=false \
    stable/jenkins # If ICP, add the --tls flag
```

Though the above command won't require you have `Dynamic Volume Provisioning` enabled nor have an existing PVC, if Jenkins pod dies/restarts for whatever reason, you will lose your Jenkins data.

### 3. Validate Jenkins Deployment
To validate Jenkins, you must obtain the Jenkins `admin` password, and the Jenkins URL.

#### 1. Obtain Jenkins `admin` password:
After you install the chart, you will see a command to receive the password that looks like follows. Note that this command might look different based on which namespace you installed it in and the chart version:
```bash
printf $(kubectl get secret --namespace default jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

Save that password as you will need it to login into Jenkins UI

#### 2. Obtain Jenkins URL:
After you install the chart, you will see a few commands to obtain the Jenkins URL that look like follows:
```bash
  export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services jenkins)
  export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT/login
```

**Note:** The `$NODE_IP` you get might or might not be accessible depending on your Kubernetes environment.

##### 2.a. Minikube Deployment
If using `minikube`, the URL commands above might not work. To open a browser to the Jenkins web portal, use the following command:
```bash
minikube service jenkins
```

##### 2.b. IBM Cloud Kubernetes Service
If using IKS, then you must use the following command to obtain the public IPs of your worker nodes as the default Jenkins install output will return the worker nodes' private IPs, which are not publicly accessible:
```bash
ibmcloud ks workers ${CLUSTER_NAME}
```

Where `${CLUSTER_NAME}` is the cluster name assigned to your cluster.

The output of the above command will look something like this:
```bash
OK
ID                           Public IP        Private IP    Machine Type        State    Status   Zone    Version
kube-dal13-somerandomid-w1   111.22.333.441   10.11.22.31   u2c.2x4.encrypted   normal   Ready    dal13   1.10.3_1513
kube-dal13-somerandomid-w2   111.22.333.442   10.11.22.32   u2c.2x4.encrypted   normal   Ready    dal13   1.10.1_1508*
kube-dal13-somerandomid-w3   111.22.333.443   10.11.33.33   u2c.2x4.encrypted   normal   Ready    dal13   1.10.1_1508*
```

Just pick the Public IP of any worker node and use it as the `NODE_IP`. Note that the output above is showing sample values.

##### 2.c. IBM Cloud Private
For ICP, the `NODE_IP` will vary on your setup, but technically the IP address of any of the worker nodes or the proxy nodes should work.

#### 3. Login to Jenkins URL
Open a new browser window and paste the URL obtained in Step 2. Then make sure you see a page that looks as follows:

![Jenkins Login](static/imgs/jenkins_login.png?raw=true)

Use the following test credentials to login:
* **Username:** admin
* **Password:** Password obtained in Step 2

If login is successful, you should see a page that looks like this

![Jenkins Login](static/imgs/jenkins_dashboard.png?raw=true)

Congratulations, you have successfully installed a Jenkins instance in your Kubernetes cluster!

#### 4. Increase Container Cap Count
Jenkins creates pods from containers in order to run jobs, sometimes creating multiple containers until one is able to run successfully. The default container cap is set to `10`, which can cause errors if multiple containers fail to create. Increase it to `1000` as follows:

![4. Increase Container Cap](static/imgs/icp_4.png?raw=true)

### Delete Jenkins Deployment
To delete the Jenkins chart from your cluster, run the following:
```bash
helm delete jenkins --purge # add --tls flag if using IBM Cloud Private
```

## Setup Docker Registry
In order to be able to build and push new images to a Docker Registry (Docker Hub or private), you will need the following information:
* **Registry Location** Docker Hub or a privately hosted Repository.
* **Registry Username**.
    + If using Docker Hub, then it is your `Docker ID`.
* **Registry Password**.
* **Registry Namespace:** An isolated location inside the registry in which to push new images
    + If using Docker Hub, then it is the same as your `Docker ID`

### Step 1: Create Docker Secret
#### DockerHub
If you don't already have a `Docker ID`, create one at https://hub.docker.com/

This information will go in a `docker-registry secret`, which you can create using the following:
```bash
kubectl create secret docker-registry registry-creds --docker-server=https://index.docker.io/v1/ --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD} --docker-email=${EMAIL}
```

Where:
* `registry-creds` is the name of the secret.
* `https://index.docker.io/v1/` is Docker Hub's Fully Qualified Domain Name.
* `${DOCKER_USERNAME}` is your `Docker ID` or username.
* `${DOCKER_PASSWORD}` is your Docker Hub password.
* `${EMAIL}` is your Docker Hub email.

#### IBM Cloud Kubernetes Service
For this guide, we are going to use the `IBM Cloud Container Registry` service to host our docker images. With an IBM Cloud account, you have access to a generous FREE tier. To do the initial setup, we recommend you follow their [Registry Quick Start](https://console.bluemix.net/containers-kubernetes/registry/start) guide, in which you will setup the required CLI components and push your first image to the registry!

Now that your registry is setup we can proceed to creating a `Registry Token`, which will be used by the Jenkins pipeline to push and pull images from the registry. This token can be made non-expiring, which is ideal for CI/CD servers that run 24/7. Also, this token is not tied to a user account, so no need to constanly enter username and passwords manually to login into docker registry.

##### 1. Create a Registry Namespace
In order to push Docker images to the IBM Cloud Container Registry, you will first need to create a globally unique namespace:
```bash
bx cr namespace-add ${NAMESPACE}
```

Where `${NAMESPACE}` is the globally unique name for your namespace.

##### 2. Create Docker Registry Token
To create a Registry Token on IBM Cloud Container Registry, run the following command:
```bash
bx cr token-add --non-expiring --readwrite --description "For Science"
```

##### 3. Create Docker Secret
```bash
# Create docker registry secret
kubectl create secret docker-registry registry-creds --docker-server=registry.ng.bluemix.net --docker-username=token --docker-password=${TOKEN} --docker-email=test@test.com
```

Where:
* `registry-creds` is the name of the secret.
* `registry.ng.bluemix.net` is the registry domain address.
* `token` is the username associated with the registry token.
* `${TOKEN}` is the actual token obtained in the previous step.
* `test@test.com` is just a sample email to associate with the token.

#### IBM Cloud Private
This information will go in a `docker-registry secret`, which you can create using the following:
```bash
kubectl create secret docker-registry registry-creds --docker-server=mycluster.icp:8500 --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD} --docker-email=test@test.com
```

Where:
* `bluemix-registry` is the name of the secret.
* `registry.ng.bluemix.net` is the registry domain address.
* `${DOCKER_USERNAME}` is the username associated with the registry token.
* `${DOCKER_PASSWORD}` is the actual token obtained in the previous step.
* `test@test.com` is just a sample email to associate with the token.


### Step 2: Patch Jenkins Service Account
When you installed the Jenkins helm chart, you also created a [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) with it, which is called `jenkins`. This is done with the `--set rbac.create=true` parameter. A service account is like a regular Kubernetes user account (i.e. admin) but for procceses rather than humans. With the service account we can interact with the Kubernetes API from running pods to do things like create, get, and delete pods, deployments, etc.

In our case, we are going to use the service account to update existing deployments with a Docker image from our private registry. Since the repository is private, the service account needs acccess to the Docker Secret (which we created in Step 1) to authenticate against Docker Hub and pull down the image into our deployment. In service account terms, this kind of secret is known as an `imagePullSecret`. To patch the service account, run the following command:
```bash
kubectl patch serviceaccount jenkins -p '{"imagePullSecrets": [{"name": "registry-creds"}]}'
```

**NOTE:** This step is not necessary if the Docker images are public. However, it is a best practice to secure your Docker registry with authentication.

### Step 3: Save Docker Credentials in Jenkins
For Jenkins to be able to safely use the Docker Registry Credentials in the pipelines (mostly in the `docker push` command), we must create a `Username with password` credentials in Jenkins. To do so, open a browser window and do the following:
* Enter the URL to your Jenkins instance and go to `Jenkins->Credentials->System->Global credentials (unrestricted)`
    + Or you can use the following URL:
    + `http://JENKINS_IP:PORT/credentials/store/system/domain/_/`
* Click on `Add Credentials`
    + Or you can use the following URL:
    + `http://JENKINS_IP:PORT/credentials/store/system/domain/_/newCredentials`
* Create `Username with password` credentials for the token:
    + Select `Username with password` as the kind.
    + Make sure the `Scope` stays as `Global`.
    + Enter your registry username as the `Username`.
    + Enter registry password as the `Password`.
    + Enter `registry-credentials-id` as the `ID`.
    + Optional: Enter a description for the credentials.
    + Press the `OK` button.
    + If successful, you should see the `username/******` credentials entry listed.

## Create and Run a Sample CI/CD Pipeline
Now that we have a fully configured Jenkins setup. Let's create a sample CI/CD [Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/) using our sample [Bluecompute Web Service](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring) from BlueCompute.

**NOTE:** Make sure you already installed the `bluecompute-ce` chart in the `default` namespace. To do so, follow the instructions in the [Install Bluecompute Reference Architecture Chart](#install-bluecompute-reference-architecture-chart) section.

Since the pipeline will create a Kubernetes Deployment, we will be using the [Kubernetes Plugin Pipeline Convention](https://github.com/jenkinsci/kubernetes-plugin#pipeline-support). This will allow us to define the Docker images (i.e. Node.js) to be used in the Jenkins Slave Pods to run the pipelines and also the configurations (ConfigMaps, Secrets, or Environment variables) to do so, if needed.

Click [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/spring/Jenkinsfile) to see the sample Pipeline we will be using.

### Step 1: Create a Sample Job
![Create a Sample Job](static/imgs/1_create_job.png?raw=true)

### Step 2: Select Pipeline Type
![Select Pipeline Type](static/imgs/2_select_pipeline_type.png?raw=true)

### Step 3: Setup Sample Pipeline
The next step is to create the pipeline parameters. You will need the following parameters with their respective default values:
* **CLOUD**: `kubernetes`.
* **NAMESPACE**: `default`.
    + Only needed if using IBM Cloud Private's Docker Registry.
* **REGISTRY**: `docker.io` if using Docker Hub or `mycluster.icp:8500` (or whatever the cluster name is) for IBM Cloud Private's Docker Registry.
* **IMAGE_NAME**: If using Docker Hub, then use `${DOCKER_USERNAME}/bluecompute-web`.
    + If using IBM Cloud Private's Docker Registry, then just use `bluecompute-web`.
* **SERVICE_ACCOUNT**: `jenkins`.
* **REGISTRY_CREDENTIALS**: `registry-credentials-id`.
    + Where `registry-credentials-id` is the Jenkins credentials that you created for the registry in [Step 3: Save Docker Credentials in Jenkins](#step-3-save-docker-credentials-in-jenkins).

To create a parameter in Jenkins, just follow the instructions below:
![Create Pipeline](static/imgs/p_2_parameters.png?raw=true)

Once you create a parameter, then fill in the details as shown below:
![Create Pipeline](static/imgs/p_2_parameters_2.png?raw=true)

Do the above for all 5 parameters.

Now scroll down to `Pipeline` section and enter the following for git repository details:
* **Repository URL:** `https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web`
* **Branch:** `spring`
* **Script Path**: `Jenkinsfile`

![Create Pipeline](static/imgs/3_setup_pipeline.png?raw=true)

Once you do the above, press the `Save` button. You have successfully setup your Build pipeline.

### Step 4: Launch Pipeline Build
![Launch Pipeline Build](static/imgs/4_launch_build.png?raw=true)

### Step 5: Open Pipeline Console Output
![Open Pipeline Console Output](static/imgs/5_open_console_output.png?raw=true)

### Step 6: Monitor Console Output
![Monitor Console Output](static/imgs/6_see_console_output.png?raw=true)

That's it! You now have setup and ran a Jenkins CI/CD pipeline for Kubernetes deployments.

## Conclusion
Congratulations on getting to the end of this document! The journey to fully automated CI/CD for Kubernetes is a bit tedious but it is worth it in the end. Here is an overview of what you have done so far:
* Provisioned 1 Kubernetes cluster.
* Installed Jenkins Chart on Kubernetes Cluster.
* Setup your Private Docker Registry.
* Setup a CI/CD pipeline, which runs from Kubernetes using Kubernetes Plugin.
* Ran the CI/CD pipeline.

With this knowledge, you will be able to setup your own fully automated Kubernetes CICD pipelines.

All that remains is to use this knowledge to put together your own pipelines and create webhooks that will trigger the pipelines via the `git push` command. There are plenty of tutorials online that explain how to setup GitHub (or any other source control) to trigger Jenkins pipelines via webhooks. We recommend that you checkout our [Microclimate guide](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-microclimate), specifically the [Create GitHub Web Hook](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-microclimate#create-github-web-hook), if you are interested in setting this up.

## Further Reading: Hybrid Cloud Setup
Most companies already have a standalone Jenkins deployment and would like to integrate new technologies (i.e. Kubernetes) with it. Also, a standalone Jenkis is usually used to deploy to multiple environments (i.e. Public Cloud for Dev and On-Premise for Prod).

To learn about this use case, we encourage you to read our `Hybrid Cloud DevOps` guideline [here](README_HYBRID.md).

## Further Reading: Using Podman as the CI/CD Container Engine
To learn more about how [podman](https://podman.io/) is a much better suited container engine for CI/CD when compared to Docker, checkout this document:

* [docs/podman.md](docs/podman.md)