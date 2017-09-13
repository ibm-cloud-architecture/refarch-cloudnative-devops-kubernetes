# DevOps for Cloud Native Reference Application

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes*

## Table of Contents
- **[Introduction](#introduction)**
- **[Architecture and CI/CD Workflow](#architecture--cicd-workflow)**
- **[Pre-Requisites](#pre-requisites)**
    * [Download required CLIs](#download-required-clis)
    * [Create a Kubernetes Cluster](#create-a-kubernetes-cluster)
- **[Deploy Jenkins to Kubernetes Cluster](#deploy-jenkins-to-kubernetes-cluster)**
    - [Install Jenkins Chart](#install-jenkins-chart)
    - [Validate Jenkins Deployment](#validate-jenkins-deployment)
- **[Delete Jenkins Deployment](#delete-jenkins-deployment)**
- **[Create and Run a Sample CI/CD Pipeline](#create-and-run-a-sample-cicd-pipeline)**
- **[Optional Deployments](#optional-deployments)**
    - [Deploy Jenkins to IBM Bluemix Container Service using IBM Bluemix Services](#deploy-jenkins-to-ibm-bluemix-container-service-using-ibm-bluemix-services)
    - [Deploy Jenkins to IBM Cloud private](#ddeploy-jenkins-to-ibm-cloud-private)


## Introduction
DevOps, specifically automated Continuous Integration and Continuous Deployment (CI/CD), is important for Cloud Native Microservice style application. This project is developed to demonstrate how to use tools and services available on IBM Bluemix to implement the CI/CD for the BlueCompute reference application.

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

- [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
- [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.

### Create a Kubernetes Cluster

The following clusters have been tested with this sample application:

- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) - Create a single node virtual cluster on your workstation
- [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
- [IBM Cloud private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud private-ce) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_1.2.0/installing/install_containers_CE.html) to install IBM Cloud private-ce.


## Deploy Jenkins to Kubernetes Cluster
### Install Jenkins Chart

As mentioned in the [**Introduction Section**](#introduction), we will be using a [Jenkins Helm Chart](#https://github.com/kubernetes/charts/tree/master/stable/jenkins) to deploy Jenkins into a Kubernetes Cluster. Before you do so, make sure that you installed all the required CLIs as indicated in the [**Pre-Requisites**](#pre-requisites).

#### 1. Initialize `helm` in your cluster:
   
```
$ helm init
```
   
This initializes the `helm` client as well as the server side component called `tiller`.
   
#### 2. Install Jenkins Chart:

```
$ helm install --name jenkins --set Master.ImageTag=2.67 stable/jenkins
```

This downloads the jenkins chart from Kubernetes Stable Charts [Repository](https://github.com/kubernetes/charts/tree/master/stable), which comes pre-installed with `helm`.

**Note** that the Jenkins Master itself takes a few minutes initialize even after showing installation success. The output of the above command will provide instructions on how to access the newly installed Jenkins Pod. For more information on the additional options for the chart, see this [document](https://github.com/kubernetes/charts/tree/master/stable/jenkins#configuration).

### Validate Jenkins Deployment
To validate Jenkins, you must obtain the Jenkins `admin` password, and the Jenkins URL.

#### 1. Obtain Jenkins `admin` password:

After you install the chart, you will see a command to receive the password that looks like follows:

```
$ printf $(kubectl get secret --namespace default jenkins-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

Save that password as you will need it to login into Jenkins UI

#### 2. Obtain Jenkins URL:

After you install the chart, you will see a few commands to obtain the Jenkins URL that look like follows:

```
$ export SERVICE_IP=$(kubectl get svc --namespace default jenkins-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
$ echo http://$SERVICE_IP:8080/login
```

Make sure that your kubernetes cluster supports service type of `LoadBalancer`.

#### 2.a Minikube Deployment 

If using `minikube`, the URL commands above might not work. To open a browser to the Jenkins web portal, use the following command:

```
$ minikube service jenkins-jenkins
```

#### 3. Login to Jenkins URL
Open a new browser window and paste the URL obtained in Step 2. Then make sure you see a page that looks as follows:

![Jenkins Login](static/imgs/jenkins_login.png?raw=true)

Use the following test credentials to login:

- **Username:** admin
- **Password:** Password obtained in Step 2

If login is successful, you should see a page that looks like this

![Jenkins Login](static/imgs/jenkins_dashboard.png?raw=true)

Congratulations, you have successfully installed a Jenkins instance in your Kubernetes cluster!

## Delete Jenkins Deployment
To delete the Jenkins chart from your cluster, run the following:

```
$ helm delete jenkins --purge
```


## Create and Run a Sample CI/CD Pipeline
Now that we have a fully configured Jenkins setup. Let's create a sample CI/CD [Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/) using our sample [Bluecompute Web Service](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/dev) from BlueCompute.

Since the pipeline will create a Kubernetes Deployment, we will be using the [Kubernetes Plugin Pipeline Convention](https://github.com/jenkinsci/kubernetes-plugin#pipeline-support). This will allow us to define the Docker images (i.e. Node.js) to be used in the Jenkins Slave Pods to run the pipelines and also the configurations (ConfigMaps, Secrets, or Environment variables) to do so, if needed.

Click [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/dev/Jenkinsfile) to see the sample Pipeline we will be using.

### Step 1: Create Docker Secret and ConfigMap
If you don't already have a `Docker ID`, create one at https://hub.docker.com/

In order to be able to build and push new images to a Docker Registry (Docker Hub or private), you will need the following information:
- **Registry Location** Docker Hub or a privately hosted Repository.
- **Registry Username** 
    - If using Docker Hub, then it is your `Docker ID`.
- **Registry Password**
- **Registry Namespace:** An isolated location inside the registry in which to push new images
    - If using Docker Hub, then it is the same as your `Docker ID`

The following 2 sections will instruct you to create a `ConfigMap` and a `Secret` in Kubernetes cluster to withold the information above, which will be used by the pipeline.

#### Step 1-a: Create Registry Config Map:
Open the `registry_config.yaml` file in `jenkins` folder, then enter a value for `namespace` (`Docker_ID` if using Docker Hub):

```
$ cd jenkins
$ kubectl create -f registry_config.yaml
```

#### Step 1-b: Create Registry Secret:
Open the `registry_secret.yaml` file in `jenkins` folder, then enter [base64 encoded](https://www.base64encode.org/) values for registry `username` and `password` (`Docker_ID` and `Docker_Password` if using Docker Hub). To `base64` encode each value, feel free to use this [tool](https://www.base64encode.org/):

```
$ cd jenkins
$ kubectl create -f registry_secret.yaml
```

### Step 2: Create a Sample Job
![Create a Sample Job](static/imgs/1_create_job.png?raw=true)

### Step 3: Select Pipeline Type
![Select Pipeline Type](static/imgs/2_select_pipeline_type.png?raw=true)

### Step 4: Setup Sample Pipeline
Please enter the following for git repository details:
- **Repository URL:** `https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web`
- **Branch:** `dev`
- **Script Path**: `Jenkinsfile`
    - If using a cluster from `Bluemix Container Service`, use `JenkinsfileBluemix` as your `Script Path`

![Setup Sample Pipeline](static/imgs/3_setup_pipeline.png?raw=true)

### Step 5: Launch Pipeline Build
![Launch Pipeline Build](static/imgs/4_launch_build.png?raw=true)

### Step 6: Open Pipeline Console Output
![Open Pipeline Console Output](static/imgs/5_open_console_output.png?raw=true)

### Step 7: Monitor Console Output
![Monitor Console Output](static/imgs/6_see_console_output.png?raw=true)

That's it! You now have setup a fully working Jenkins CI/CD pipeline for Kubernetes deployments.

## Optional Deployments

### Deploy Jenkins to IBM Bluemix Container Service using IBM Bluemix Services
#### Install Jenkins Chart
##### 1. Create Persistent Volume Claim (PVC)
To create a Persistent Volume Claim (PVC), use the commands below:

```
$ cd jenkins/bluemix
$ kubectl create -f bluemix_pvc.yaml
```

**Note:** that the minimum PVC size for Bluemix is `20GB`.

Before you are able to use your PVC, it needs to be `Bound` to the cluster. To check it's provisioning status, use the following command:

```
$ kubectl get pvc jenkins-home
NAME           STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS       AGE
jenkins-home   Bound     pvc-a888eb22-926e-11e7-a061-86e0215fba28   20Gi       RWO           ibmc-file-silver   1m
```

You should now see a new entry for `jenkins-home` with a status of `Bound`, which means that the PVC is ready to be used to install the Jenkins Chart.

##### 2. Install Jenkins Chart
Use the following command to install the Jenkins chart:

```
$ helm install --name jenkins --version=0.8.7 --set Persistence.ExistingClaim=jenkins-home stable/jenkins 
```

Where `jenkins-home` is the PVC created in previous step.

**Note** that the Jenkins pod takes a while to fully initialyze after successful installation.

##### 3. Enable HTTPS Certificate Validation
In order for the Jenkins master pod to establish and verify a secure connection with the slave pods, you must set the **Kubernetes URL** to `https://10.10.10.1/`. Please follow the steps in the diagram below.

![HTTPS Certificate Check](static/imgs/kubernetes.png?raw=true)

That's it! You now have a fully working version of Jenkins on your Kubernetes Deployment

#### Setup Private Docker Registry
##### 1. Create Namespace in Bluemix Registry
In order to be able to push and pull images from Bluemix's private registry, you will need to create a namespace. To do so, use the following commands:

```
$ bx cr login
$ bx cr namespace-add <unique_namespace_id>
```

Where,

- `<unique_namespace_id>` is a globally unique namespace id within Bluemix's private registry.

##### 2. Create Bluemix Config Map:
In order to push/pull images from Bluemix Registry, we need to create a config map in Kubernetes cluster. To do so, open `bluemix_config.yaml` file in `jenkins/bluemix` and enter values for the following fields under `data`:

- **bluemix-api-endpoint**: Please enter Bluemix API Endpoint if using a region other than `US South`.
- **bluemix-org:** Bluemix Org for your account.
- **bluemix-space:** Bluemix Space for your account.
- **bluemix-registry:** Please enter Bluemix Registry Endpoint if using a region other than `US South`.
- **bluemix-registry-namespace:** Enter the `unique_namespace_id` from last step.
- **kube-cluster-name:** Enter your kubernetes cluster name.

To create the config map, use the following commands:

```
$ cd jenkins/bluemix
$ kubectl create -f bluemix_config.yaml.yaml
```

##### 3. Create Bluemix API Key Secret:
Open the `bluemix_secret.yaml` file in `jenkins/bluemix` folder, then enter your Bluemix API key in [base64 format](https://www.base64encode.org/) in the `api-key` field under `data`. To create the secret, use the following command

```
$ cd jenkins/bluemix
$ kubectl create -f registry_secret.yaml
```

Congratulations, you have succesfully installed configured Private Registry access and are now ready to create and run [Sample CICD Pipelines](#create-and-run-a-sample-cicd-pipeline)

### Deploy Jenkins to IBM Cloud private
#### Install Jenkins Chart
##### 1. Create MountPoint from NFS server:
You will need to create a mountpoint from NFS server. SSH to your NFS server and do the following:

```
$ cd /storage
$ mkdir jenkins-home
```

##### 2. Create Persistent Volume
Create a Persistent Volume at the mountpoint from step above as follows:

1. Click on the three bars in the top left corner, and go to `Infrastructure > Storage`.
2. Click on the `Storage` tab
3. Click on `Create Storage` button. Then enter the following values:

![1. Create Persistent Volume](static/imgs/icp_1.png?raw=true)

![2. Create Persistent Volume](static/imgs/icp_2.png?raw=true)
   
You should now see a new entry for `jenkins-home` with a status of `Available`, which means it can now be claimed by a Persitent Volume Claim.

##### 3. Create Persistent Volume Claim (PVC)
In order to use the newly created `jenkins-home` volume, you will need to create a Persistent Volume Claim (PVC) as follows:

1. Click on the `Volume` tab.
2. Click on the `Create Volume` button. Then enter the following values:

![3. Create Persistent Volume Claim](static/imgs/icp_3.png?raw=true)
    
You should now see a new entry for `jenkins-home` with a status of `Bound`, which means that the PVC is ready to be used to install the Jenkins Chart.

##### 4. Install Jenkins Chart
To install the Jenkins Chart, SSH into the NFS/Jumpbox and do the following.

1. Open ICp Dashboard, then click the `User` icon on top right.
2. Click `Configure Client` and copy all the CLI contents shown.
3. SSH into the NFS/Jumpbox.
4. Paste the contents of `Configure Client` and press enter. `kubectl` is now configured to install the chart.
5. Enter the following command to Install Jenkins chart:

```
$ helm install --name jenkins --set Persistence.ExistingClaim=jenkins-home --set Master.ImageTag=2.67 stable/jenkins
```

Where `jenkins-home` is the PVC created in previous steps.

**Note** that the Jenkins pod takes a while to fully initialyze after successful installation.

##### 5. Increase Container Cap Count
Jenkins creates pods from containers in order to run jobs, sometimes creating multiple containers until one is able to run successfully. The default container cap is set to `10`, which can cause errors if multiple containers fail to create. Increase it to `1000` as follows:

![4. Increase Container Cap](static/imgs/icp_4.png?raw=true)


#### Setup Private Docker Registry
You will need perform additional setup in order to be able to build and push new images to ICp's Private Registry. The following 3 section will instruct you to create the following:

- Dedicated registry `user` for `jenkins`
- Configmap for `registry` and `namespace`
- Secret for registry `username` and `password`

##### 1. Create Jenkins User:
The `jenkins` user will have access to create, push, and deploy images from the Private Registry in a CICD pipeline. To create user, do the following:

1. Click on the three bars in the top left corner, and go to `System`.
2. Click on the `Users` tab
3. Click on `New User` button. Then enter the following values:
    - **Namespace:** `default`
    - **Name:** `jenkins`
    - **Password:** `passw0rd`
    - **Email:** Enter your email address.

##### 2. Create Registry Config Map:
The `registry_config_icp.yaml` file in `jenkins/ibm_cloud_private` already contains the appropriate values for `registry` and `namespace`. To create config map, enter the commands below from `NFS/Jumpbox`:

```
$ cd jenkins/ibm_cloud_private
$ kubectl create -f registry_config_icp.yaml
```

##### 3. Create Registry Secret:
Open the `registry_secret.yaml` file in `jenkins` folder, then enter the following [base64 encoded](https://www.base64encode.org/) values for registry `username` and `password`:

- **username:** `amVua2lucwo=`
    - base64 for `jenkins`
- **password:** `cGFzc3cwcmQK`
    - base64 for `passw0rd`

```
$ cd jenkins
$ kubectl create -f registry_secret.yaml
```

Congratulations, you have succesfully installed configured Private Registry access and are now ready to create and run [Sample CICD Pipelines](#create-and-run-a-sample-cicd-pipeline)