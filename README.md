# DevOps for Cloud Native Reference Application

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes*

## Table of Contents
- **[Introduction](#introduction)**
- **[Architecture and CI/CD Workflow](#architecture-and-cicd-workflow)**
- **[Pre-Requisites](#pre-requisites)**
- **[Install and Setup Jenkins on Kubernetes](#install-and-setup-jenkins-on-kubernetes)**
- **[Create and Run a Sample CI/CD Pipeline](#create-and-run-a-sample-cicd-pipeline)**

## Introduction
DevOps, specifically automated Continuous Integration and Continuous Deployment (CI/CD), is important for Cloud Native Microservice style application. This project is developed to demonstrate how to use tools and services available on IBM Bluemix to implement the CI/CD for the BlueCompute reference application.

The project uses the [Jenkins Helm Chart](https://github.com/kubernetes/charts/tree/master/stable/jenkins) to install a Jenkins Master pod with the [Kubernetes Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Kubernetes+Plugin) in a Kubernetes Cluster. [**Helm**](https://github.com/kubernetes/helm) is Kubernetes's package manager, which facilitates deployment of prepackaged Kubernetes resources that are reusable. This setup allows Jenkins to spin up ephemeral pods to run Jenkins jobs and pipelines without the need of Always-On dedicated Jenkins slave/worker servers, which reduces Jenkins's infrastructural costs.

Let's get started.

## Architecture & CI/CD Workflow
Here is the High Level DevOps Architecture Diagram for the Jenkins setup on Kubernetes, along with a typical CI/CD workflow:

![DevOps Toolchain](static/imgs/architecture.png?raw=true)  

This guide will install the following resources:
* 1 x 20GB [Bluemix Kubernetes Persistent Volume Claim](https://console.ng.bluemix.net/docs/containers/cs_apps.html#cs_apps_volume_claim) to Store Jenkins data and builds' information.
* 1 x Jenkins Master Kubernetes Pod with Kubernetes Plugin Installed.
* 1 x Kubernetes Service for above Jenkins Master Pod with port 8080 exposed to a LoadBalancer.
* All using Kubernetes Resources.

## Pre-Requisites
1. **CLIs for Bluemix, Kubernetes, Helm, JQ, and YAML:** Run the following script to install the CLIs:

    `$ ./install_cli.sh`

2. **Bluemix Account.**
    * Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration).
    * Once you have logged in, create a new space for hosting the application in US-Southregions.
3. **Paid Kubernetes Cluster:** If you don't already have a paid Kubernetes Cluster in Bluemix, please go to the following links and follow the steps to create one.
    * [Log into the Bluemix Container Service](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#step-2-provision-a-kubernetes-cluster-on-ibm-bluemix-container-service).
    * [Create a paid Kubernetes Cluster](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#paid-cluster).

## Install and Setup Jenkins on Kubernetes
### Step 1: Install Jenkins on Kubernetes Cluster
As mentioned in the [**Introduction Section**](#introduction), we will be using a Jenkins Helm Chart to deploy Jenkins into a Bluemix Kubernetes Cluster. Before you do so, make sure that you installed all the required CLIs as indicated in the [**Pre-Requisites**](#pre-requisites).

Here is a script that installs the Jenkins Chart for you:

```
$ cd jenkins
$ ./install_jenkins.sh <cluster-name> <Optional:bluemix-space-name> <Optional:bluemix-api-key>
```

The output of the above script will provide instructions on how to access the newly installed Jenkins Pod.

**Note** that the Jenkins Master itself takes a few minutes initialize even after showing installation success

The `install_jenkins.sh` script does the following:
* **Log into Bluemix.**
* **Creates Container Registry Namespace**, which is used by Jenkins Pipelines to push new Docker images for new builds.
* **Set Terminal Context to Kubernetes Cluster.**
* **Initialize Helm Client and Server (Tiller).**
* **Create Config Map,** which the Slave Pods use to know log into Bluemix and Push new Build Images to the private Bluemix Container Registry.
* **Create Secret,** which is needed to authenticate against Bluemix and Container Registry Service.
* **Create Jenkins Persistent Volume Claim,** which is where all Jenkins and build related data is stored and read by Jenkins Master Pods and Slave Pods.
* **Install Jenkins Chart on Kubernetes Cluster using Helm.**

### Step 2: Enable HTTPS Certificate Validation
In order for the Jenkins master pod to establish and verify a secure connection with the slave pods, you must set the **Kubernetes URL** to `https://10.10.10.1/`. Please follow the steps in the diagram below.

![HTTPS Certificate Check](static/imgs/kubernetes.png?raw=true)  

That's it! You now have a fully working version of Jenkins on your Kubernetes Deployment

## Create and Run a Sample CI/CD Pipeline
Now that we have a fully configured Jenkins setup. Let's create a sample CI/CD [Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/) using our sample [Inventory Service](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/kube-int) from BlueCompute.

Since the pipeline will create a Kubernetes Deployment, we will be using the [Kubernetes Plugin Pipeline Convention](https://github.com/jenkinsci/kubernetes-plugin#pipeline-support). This will allow us to define the Docker images (i.e. Java to build Gradle projects) to be used in the Jenkins Slave Pods to run the pipelines and also the configurations (ConfigMaps, Secrets, or Environment variables) to do so, if needed.

Click [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/kube-int/inventory/Jenkinsfile) to see the sample Pipeline we will be using.

Also, feel free to checkout the images we created to run the pipelines that deploy the different microservices in Bluecompute app. They are located in the `docker_images` folder.

### Step 1: Create a Sample Job
![Create a Sample Job](static/imgs/1_create_job.png?raw=true)

### Step 2: Select Pipeline Type
![Select Pipeline Type](static/imgs/2_select_pipeline_type.png?raw=true)

### Step 3: Setup Sample Pipeline
![Setup Sample Pipeline](static/imgs/3_setup_pipeline.png?raw=true)

### Step 4: Launch Pipeline Build
![Launch Pipeline Build](static/imgs/4_launch_build.png?raw=true)

### Step 5: Open Pipeline Console Output
![Open Pipeline Console Output](static/imgs/5_open_console_output.png?raw=true)

### Step 6: Monitor Console Output
![Monitor Console Output](static/imgs/6_see_console_output.png?raw=true)

That's it! You now have setup a fully working Jenkins CI/CD pipeline for Kubernetes deployments.