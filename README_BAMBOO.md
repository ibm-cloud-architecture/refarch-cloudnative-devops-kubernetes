# Using Atlassian Suite to run CI/CD pipelines for IBM Cloud Private

## Table of Contents
  * [Introduction](#introduction)
  * [Architecture Diagram](#architecture-diagram)
  * [Pre-Requisites](#pre-requisites)
  * [1. ICP Setup](#1-icp-setup)
    + [a. Install Microservices Reference Architecture Chart on ICP](#a-install-microservices-reference-architecture-chart-on-icp)
    + [b. Create Bamboo Service Account on ICP](#b-create-bamboo-service-account-on-icp)
  * [2. Install JIRA](#2-install-jira)
    + [a. JIRA Installation](#a-jira-installation)
      - [Optional: JIRA Docker installation](#optional-jira-docker-installation)
    + [b. Create JIRA user server applications for Bamboo and Bitbucket](#b-create-jira-user-server-applications-for-bamboo-and-bitbucket)
  * [3. Install Bamboo](#3-install-bamboo)
    + [a. Create Bamboo User](#a-create-bamboo-user)
    + [b. Java Installation](#b-java-installation)
    + [c. Bamboo Installation](#c-bamboo-installation)
    + [d. Connect Bamboo to JIRA user server](#d-connect-bamboo-to-jira-user-server)
    + [e. Install Docker](#e-install-docker)
    + [f. Install kubectl](#f-install-kubectl)
    + [g. Upload ICP Kubeconfig file to Bamboo](#g-upload-icp-kubeconfig-file-to-bamboo)
      - [Optional: Bamboo Docker installation](#optional-bamboo-docker-installation)
    + [h. Create Application Link with JIRA from Bamboo](#h-create-application-link-with-jira-from-bamboo)
    + [i. Create Docker and Kubernetes Capabilities](#i-create-docker-and-kubernetes-capabilities)
    + [j. Add Global Variables](#j-add-global-variables)
  * [4. Install Bitbucket](#4-install-bitbucket)
    + [a. Bitbucket Installation](#a-bitbucket-installation)
      - [Optional: Bitbucket Docker installation](#optional-bitbucket-docker-installation)
    + [b. Connect Bitbucket to JIRA user server](#b-connect-bitbucket-to-jira-user-server)
    + [c. Create Application Link with JIRA and Bamboo from Bitbucket](#c-create-application-link-with-jira-and-bamboo-from-bitbucket)
  * [5. JIRA, Bitbucket, and Bamboo Integration](#5-jira-bitbucket-and-bamboo-integration)
    + [a. Create Bluecompute Web BLUEWEB Project in JIRA](#a-create-bluecompute-web-blueweb-project-in-jira)
    + [b. Create a JIRA Issue](#b-create-a-jira-issue)
    + [c. Add your SSH Key to Bitbucket](#c-add-your-ssh-key-to-bitbucket)
    + [d. Create the Bluecompute Project in Bitbucket](#d-create-the-bluecompute-project-in-bitbucket)
    + [e. Create and Setup bluecompute-web Git Repository on Bitbucket](#e-create-and-setup-bluecompute-web-git-repository-on-bitbucket)
    + [f. Create the Bluecompute Project on Bamboo](#f-create-the-bluecompute-project-on-bamboo)
    + [g. Create the bluecompute-web Plan on Bamboo](#g-create-the-bluecompute-web-plan-on-bamboo)
      - [i. Import the bluecompute-web repository in Bamboo](#i-import-the-bluecompute-web-repository-in-bamboo)
      - [ii. Enable Spec Scanning and Project Access for the `bluecompute-web` Repository](#ii-enable-spec-scanning-and-project-access-for-the-bluecompute-web-repository)
      - [iii. Enable bluecompute-web Repository to Create Plans in the Bluecompute Bamboo Project](#iii-enable-bluecompute-web-repository-to-create-plans-in-the-bluecompute-bamboo-project)
  * [6. Integration Test](#6-integration-test)
    + [a. Create and Push Test Commit to Trigger the Bamboo Build](#a-create-and-push-test-commit-to-trigger-the-bamboo-build)
    + [b. View Build Status on Bamboo](#b-view-build-status-on-bamboo)
    + [c. View Bamboo Build Results and Bitbucket Commits on JIRA](#c-view-bamboo-build-results-and-bitbucket-commits-on-jira)
    + [d. Optional: Verify Changes in the Bluecompute Web Home Page on ICP](#d-optional-verify-changes-in-the-bluecompute-web-home-page-on-icp)
  * [Conclusion](#conclusion)

## Introduction
Adopting new technology, such as IBM Cloud Private (ICP), is easier when you can integrate it with your existing technology stack. The Atlassian suite of software development tools (JIRA, Bamboo, and Bitbucket, amongst others) are widely adopted amongst organizations and are used for end-to-end software development cycles, amongst other things.

The goal of this document is to teach you how you can, on a basic level, use an existing Atlassian (JIRA, Bamboo, and Bitbucket) to:
* Trigger a Bamboo CI/CD Pipeline from Bitbucket that will update an existing Kubernetes deployment on ICP.
* Have both Bitbucket and Bamboo commit history and build results, respectively, to a JIRA issue.

## Architecture Diagram
Here is a diagram of what we will be playing with today:
COMING SOON

The end-goal workflow we are going to run through, after setting up and configuring all the tools and infrastructure, is the following:
1. Commit a new change in code and write the JIRA issue as part of the commit message, which will make it show on JIRA issue.
2. Push the code to Bamboo repository, which will trigger an automated Bamboo build.
3. The Bamboo automated build will build and push a new Docker image to ICP's private Docker registry.
4. The Bamboo automated build will check for an existing Kubernetes Deployment in ICP cluster and update it with the new image.
5. Once the Bamboo build is finished, it will post the build results (successful or not) to the JIRA issue mentioned in the commit history.

On a basic level, the above is the workflow we want to prove. Later on you will learn how to verify things like how to check the actual Docker image that the Kubernetes deployment was updated with.

## Pre-Requisites
This guide will require some infrastructure to host ICP along with JIRA, Bamboo, and Bitbucket and will assume that you already have that infrastructure available at your disposal. Here is what you will need:
* An [IBM Cloud Private Cluster](https://github.com/IBM/deploy-ibm-cloud-private).
	+ For more install options, check out this [document](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html).
* 3 Ubuntu VMs: This guide was tested on Ubuntu 16.04.4 Xenial
	+ Create a root password on all of them
	```bash
	$ sudo su
	$ passwd
	```
	+ Enable root ssh on all of them
	```bash
	# Install openssh
	$ sudo su
	$ apt-get update
	$ apt-get install -y openssh-server
	# Enable root ssh
	$ sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config
	$ systemctl restart ssh
	```

## 1. ICP Setup
Before we start using Bamboo to update an ICP Kubernetes Deployment, we need to have a deployment to update in the first place. Then we need to provide Bamboo with the access/priviledges it needs to do so.

### a. Install Microservices Reference Architecture Chart on ICP
As our deployment, we are going to install our microservices reference architecture app, called `bluecompute-ce`, in the `default` namespace on our ICP cluster. To Install `bluecompute-ce`, follow the instructions in the link below:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#deploy-bluecompute-to-ibm-cloud-private

To learn more about the reference architecture application, feel free to check out its README page in the link below:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#introduction

### b. Create Bamboo Service Account on ICP
In order for Bamboo to be able to update a deployment on ICP, we are going to create a [Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) and are going to assign to it the `admin` role as a [ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).
```bash
# Create the bamboo service account in the default namespace
$ kubectl create sa bamboo --namespace default

# Bind the admin cluster role to the bamboo service account
$ kubectl create clusterrolebinding "bamboo-binding" --clusterrole=admin --serviceaccount="default:bamboo"
```

**NOTE:** In a real world scenario, we recommend you assing a non-admin role with less priviledges to your service account.

Now we need download the Certificate of Authority (CA) and the Service Account Token so that we can create a configuration file that we can upload to Bamboo later.
```bash
# Specify path where config file will reside
# Mac
$ CONFIG_FOLDER="/Users/${USER}/.kube/config-default-bamboo"
# Linux
$ CONFIG_FOLDER="/home/${USER}/.kube/config-default-bamboo"

# Create config folder
$ mkdir -p "${CONFIG_FOLDER}"

# Get Service Account Secret Name
$ SECRET_NAME=$(kubectl get sa bamboo --namespace default -o=jsonpath='{.secrets[0].name}';echo)

# Extract CA certificate from secret
$ kubectl get secret "${SECRET_NAME}" --namespace default -o=jsonpath='{.data.ca\.crt}' | base64 -D > "${CONFIG_FOLDER}/ca.crt"

# Extract Service Account Token
$ TOKEN=$(kubectl get secret "${SECRET_NAME}" --namespace default -o=jsonpath='{.data.token}' | base64 -D)
```

Now let's create the configuration file itself:
```bash
# Get ICP Cluster name
$ CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)

# Get ICP URL
$ ICP_URL=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")

# Create the kubeconfig file for cluster name
$ kubectl config set-cluster "${CLUSTER_NAME}" --kubeconfig="${CONFIG_FOLDER}/config.yaml" --server="${ICP_URL}" --certificate-authority="${CONFIG_FOLDER}/ca.crt" --embed-certs=true

# Put the service account token in the config file
$ kubectl config set-credentials "bamboo-default-${CLUSTER_NAME}" --kubeconfig="${CONFIG_FOLDER}/config.yaml" --token="${TOKEN}"

# Create a context for cluster
$ kubectl config set-context "bamboo-default-${CLUSTER_NAME}" --kubeconfig="${CONFIG_FOLDER}/config.yaml}" --cluster="${CLUSTER_NAME}" --user="bamboo-default-${CLUSTER_NAME}" --namespace="${NAMESPACE}"

# Set the current-context to the above context
$ kubectl config use-context "bamboo-default-${CLUSTER_NAME}" --kubeconfig="${CONFIG_FOLDER}/config.yaml}"
```

That should be it. Now to make sure everything works, run the following command to get pods using the service account:
```bash
$ KUBECONFIG="${CONFIG_FOLDER}/config.yaml}" kubectl get pods
```

**NOTE:** We also provided a script that does the above for you in [scripts/k8s_create_service_account.sh](scripts/k8s_create_service_account.sh). There is also a script that deletes the service accounts for you in [scripts/k8s_create_service_account.sh](scripts/k8s_create_service_account.sh).

## 2. Install JIRA
JIRA is a popular tool for software development planning. One of its greatest features is that it allows for other apps (Atlassian or 3rd party) to connect into it to provide status updates, such as Bitbucket commit history and Bamboo build reports.

### a. JIRA Installation
To install JIRA, follow the instructions from Atlassian's JIRA website below:
* https://confluence.atlassian.com/adminjiraserver/installing-jira-applications-on-linux-938846841.html#InstallingJiraapplicationsonLinux-3.Choosesetupmethod

Once you install JIRA, go ahead create an admin account and log into it on your browser.

#### Optional: JIRA Docker installation
If you don't have a host to install JIRA on, then you could try running JIRA from a docker container. Here are a couple of Docker images found on Docker Hub:
* https://hub.docker.com/r/cptactionhank/atlassian-jira/
* https://hub.docker.com/r/cptactionhank/atlassian-jira-software/

**NOTE:** We are not associated to the author of the Docker images above and you should use it at your own expense.

### b. Create JIRA user server applications for Bamboo and Bitbucket
Another advantage of JIRA is that it can serve as the user directory for other Atlassian products, such as Bamboo and Bitbucket. Ideally, you have your own external user directory setup, such as LDAP, and have all these apps connect to it. But for this guide, using JIRA as a user diretory serves our purposes. The idea is to have a central location to users and user groups instead of doing it independenty for each app.

There are 2 steps to setup the JIRA user server for any Atlassian application:
* First you create application credentials on JIRA that another application can use to connect to the JIRA user server.
* Then on the application itself (i.e. Bamboo), you specify the JIRA URL and the application credentials to connect.

Since we don't have Bamboo nor Bitbucket setup yet, we are going to start by creating application credentials for each application from JIRA. To do so, follow these steps on JIRA from a browser window:
* Click on Cog Icon on top right, then click on `User Management`, then click on `JIRA user server` section on the left under `USER MANAGEMENT`
	+ Or you can go to `http://JIRA_IP:8080/secure/admin/ConfigureCrowdServer.jspa` on your browser
* Click `+ Add application` button.
	+ Or you can go to `http://JIRA_IP:8080/secure/admin/EditCrowdApplication.jspa` on your browser
* Now fillout the presented form as follows:
	+ **Application name:** Enter `bamboo`.
	+ **Password:** Enter `letmein`.
	+ **IP Addresses:** Delete what's listed and enter the IP address for what's gonna be Bamboo's host.
		- If you don't have the IP address yet, then you can come back later when you have Bamboo's host ready.
* Click the `Save` button.

Now repeat the same steps for `Bitbucket`.

Remember this is just the first step to setting up the JIRA user server. Once Bamboo and Bitbucket are setup, we have to next step, which is connecting Bamboo and Bitbucket to JIRA user server using the credentials we created above.

## 3. Install Bamboo
Bamboo is a CI/CD server deployed by Atlassian that can be easily connected to git repositories to trigger a CI/CD job. It can also be used along with JIRA to provide build reports on specific JIRA issues.

Bamboo runs jobs on agents, much like Jenkins slaves. These agents must have the required set of tools installed on them to be able to run these jobs.

For the sake of this document, we will have a single agent Bamboo server with the following tools installed:
* Docker
* kubectl
* Kubernetes configuration file we created earlier

The above tools will allow us to build and push new docker Images to ICP's Private Docker registry and use `kubectl` to update the deployment on ICP directly from the Bamboo agent.

### a. Create Bamboo User
To run Bamboo as a service (which you'll learn how to do later on) you need to create a dedicated `bamboo`. To do so, run the following command:
```bash
# Create bamboo user
$ sudo /usr/sbin/useradd --create-home --home-dir /usr/local/bamboo --shell /bin/bash bamboo

# Become the bamboo user
$ sudo su - bamboo

# Create a password
$ passwd
```

The password will be used later when transfering the kubeconfig file to the `bamboo` user's home directory.

### b. Java Installation
Before you can install Bamboo, you will need to install Java OpenJDK as Bamboo requires it. To Install OpenJDK, run the following commands.
```bash
# Install java and ssh
$ sudo apt-get update

# Java Installation
$ sudo apt-get install -y default-jdk
$ sudo echo "JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java\"" >> /etc/environment

# Become bamboo user
$ sudo su - bamboo

# Add Java to JAVA_HOME
$ touch ~/.bashrc
$ echo "source /etc/environment" >> ~/.bashrc
$ . ~/.bashrc

# Check that JAVA_HOME is set properly
$ echo $JAVA_HOME
/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
```

### c. Bamboo Installation
To install Bamboo, we recommend that you install and run Bamboo as a Linux service. To do so, we recommend you run the following guide from Atlassian. **Note** that we already created the `bamboo` user earlier, so you can skip that step in the guide below:
https://confluence.atlassian.com/bamboo/running-bamboo-as-a-linux-service-416056046.html

### d. Connect Bamboo to JIRA user server
Now that Bamboo is ready, we should connect it to JIRA user server to avoid managing user credentials in multiple places. To do so, follow Atlassian's guide below. **Note** that we already did Step 1 earlier after installing JIRA:
* https://confluence.atlassian.com/bamboo/connecting-bamboo-to-jira-for-user-management-952604122.html#ConnectingBambootoJIRAforusermanagement-jira

### e. Install Docker
To Install docker on Ubuntu Xenial, run the following steps:
```bash
# Become sudo
$ sudo su

# Update package repository
$ apt-get update

# Install docker
$ apt-get install -y docker.io

# Run docker hello world to check everything works
$ docker run hello-world

# Create docker group if it doesn't already exist
$ groupadd docker

# Add the bamboo user to docker group
# The bamboo user was created during Bamboo installation to run it as a service
# In order for Bamboo to run docker from the CI/CD jobs, we need to add the bamboo user to the docker group
$ gpasswd -a bamboo docker

# Activate the changes to docker group
$ newgrp docker

# Now become the bamboo user and run docker hellow world to verity that everything works
$ sudo su - bamboo
$ docker run hello-world
```

Docker is now installed! But before we can push docker images to ICP's private Docker registry, we need to add an entry for it in Docker's insecure registries and in /etc/hosts. To add ICP private registry to insecure Docker registries, do the following:
```bash
# Open the /etc/docker/daemon.json with your preferred text editor
$ sudo vim /etc/docker/daemon.json

# Enter the following content:
{
    "insecure-registries" : [ "http://${CLUSTER_NAME}:8500" ]
}

# Then restart docker docker
$ sudo systemctl restart docker
```

Where `${CLUSTER_NAME}` is the name of your ICP cluster.

To add ICP cluster to /etc/hosts, do the following:
```bash
$ echo "${CLUSTER_MASTER_IP} ${CLUSTER_NAME}"
```

Where `${CLUSTER_MASTER_IP}` is the IP address of your ICP master node and `${CLUSTER_NAME}` is the name of your ICP cluster.

To verify that everything works, login to ICP's private Docker registry using your ICP user credentials as follows:
```bash
$ docker login -u "${USERNAME}" -p "${PASSWORD}" "${CLUSTER_NAME}:8500"
```

Where:
* `${USERNAME}` is your ICP username.
	+ The default username is `admin`.
* `${PASSWORD}` is your ICP password.
	+ The default password is `admin`, which you should definitely not use in Production.
* `${CLUSTER_NAME}` is your ICP Cluster's name as entered in `/etc/hosts`

If the login succeeded, then that means that Docker is fully setup and ready to be used by Bamboo!

### f. Install kubectl
`kubectl` will be used to update the Kubernetes deployment on ICP. To install `kubectl` in Bamboo, run the following commands:
```bash
$ sudo apt-get update && sudo apt-get install -y apt-transport-https
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ sudo touch /etc/apt/sources.list.d/kubernetes.list 
$ echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubectl
```

If you have any issues, you can refer to `Install kubectl binary via native package management` section of the kubectl installation guide here:
* https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl

### g. Upload ICP Kubeconfig file to Bamboo
Bamboo will need the ICP config file for `kubectl` to successfully authenticate against ICP's Kubernetes API and be able to update deployments. To do so, first you need to do the following in the Bamboo host:
```bash
# Login as the bamboo user
$ sudo su - bamboo

# Create the kube directory where the config file will reside
$ mkdir ~/.kube
```

Now from your laptop or wherever you have the kubeconfig file, run the following command:
```bash
$ scp /path/to/config.yml bamboo@${BAMBOO_IP}:~/.kube
```

Log back into Bamboo host as the `bamboo` user and run the following commands:
```bash
# Login as the bamboo user
$ sudo su - bamboo

# Test that kubectl can talk with ICP
$ KUBECONFIG=/home/bamboo/.kube/config.yml kubectl get pods
```

If you are able to see pods and get no errors, then kubectl is ready to be used by Bamboo!

#### Optional: Bamboo Docker installation
If you don't have a host to install Bamboo on, then you could try running Bamboo from a docker container. Here is a Docker image found on Docker Hub:
* https://hub.docker.com/r/cptactionhank/atlassian-bamboo/

**NOTE:** We are not associated to the author of the Docker images above and you should use it at your own expense. Also, in order to fully utilize this image, you will have to ssh into the Bamboo container and install the requirements mentioned in the previous sections. Or you could build your own Docker image based on the above image.

### h. Create Application Link with JIRA from Bamboo
This step is necessary so that JIRA and Bamboo are aware of each other and so that Bamboo can provide JIRA with build information related to a specific issue. To create an application link with JIRA, do the following steps:
* Click on Cog Icon->Overview.
	+ Or open http://${BAMBOO_IP}:8085/admin/administer.action in your browser.
* Click on `Application links` under `ADD-ONS`
	+ Or open http://${BAMBOO_IP}:8085/plugins/servlet/applinks/listApplicationLinks in your browser.
* On the text box, enter the URL for JIRA in the format of http://${JIRA_IP}:8080, then click on `Create new link` button.
* On the pop up that shows up, make sure the URLs are correct and check the box that says `The servers have the same set of users and usernames.`, then click on `Continue`.
* You will then be redirected to JIRA and may be asked to enter your admin credentials.
	+ If asked for credentials, enter your admin login credentials and click `Confirm` button.
* Once you are in JIRA, a pop up will come up to ask you to do the application like to Bamboo from the JIRA side
	+ Make sure the information is correct, then click the `Continue` button.
* If all went well, you will be redirected back to Bamboo and will see a dialogue with a green checkmark saying something like `Application Link 'JIRA' created successfully.`

You have successfully make the application link to JIRA.

### i. Create Docker and Kubernetes Capabilities
The more Bamboo agents you have, the more you have to be aware of their capabilities in order to match jobs to capable agents. Bamboo is good at detecting common capabilities (i.e. JDK, Git, Docker, etc) in agents. For our case, we need to make sure that the agents have the `Docker` and the `Kubernetes` capability. All that means is that our agents should know where to find the `docker` and `kubectl` binaries. To add the capabilities, do the following:
* Click on Cog Icon->Overview.
	+ Or open http://${BAMBOO_IP}:8085/admin/administer.action in your browser.
* Click on `Server capabilities` under `BUILD RESOURCES`.
	+ Or open http://${BAMBOO_IP}:8085/admin/agent/configureSharedLocalCapabilities.action in your browser.
* If you don't already see the `Docker` capability, add `Docker` by going to the `Add capability` section at the bottom.
	+ Select `Docker` in the `Capability type` dropdown.
	+ Enter the path to Docker in the `Path` field, which is usually `/usr/bin/docker`.
	+ Click the `Add` button to finish adding the capability.
* Add the `kubectl` capability.
	+ Selecting `Executable` in the `Capability type`.
	+ Select `Command` in the `Type` field.
	+ Enter `kubectl` for `Executable label` field.
	+ Enter `/usr/local/bin/kubectl` (or wherever kubectl is located in the host) in the `Path` field.
	+ Click the `Add` button to finish adding the capability.

You have successfully added the Docker and kubectl capabilities to your Baboo agent!

### j. Add Global Variables
In order for our pipelines to access the ICP Docker repository and make updates to the Bluecompute Web Deployment, it needs access to the Docker registry credentials and the kubeconfig file respectively. Since this is information is dynamic, it is a security best practice to store the configuration in Bamboo instead of in the pipeline directly. To keep things simple, we will use the `Global variables` for our configuration as following:
* Click on Cog Icon->Global variables.
	+ Or open http://${BAMBOO_IP}:8085/admin/configureGlobalVariables.action in your browser.
* Create the following variables with their respective values:
	+ `REGISTRY`:
		- Enter `${YOUR_ICP_CLUSTER_NAME}:8500` for the value.
		- Click the `Add` button.
	+ `REGISTRY_USER`:
		- Enter your ICP username for the value.
		- Click the `Add` button.
	+ `REGISTRY_PASSWORD`:
		- Enter your ICP password for the value.
		- Click the `Add` button.
	+ `K8S_NAMESPACE`:
		- Enter `default` for the value.
		- Click the `Add` button.
	+ `K8S_CFG_FILE_PATH`:
		- Enter `/home/bamboo/.kube/config.yml` (or whatever path you chose for the kubeconfig file) for the value.
		- Click the `Add` button.

You have successfully configured Global Variables!

## 4. Install Bitbucket
Bitbucket Server (formerly Stash) is a self-hosted version control repository made by Atlassian that can be deployed on-premise. If connected with JIRA, it can provide JIRA issues with commit history. Also, if connected with Bamboo, new commits can trigger CI/CD jobs on Bamboo, which can then provide build results to JIRA.

### a. Bitbucket Installation
To install Bamboo, we recommend that you install and run Bitbucket as a Linux service. To do so, we recommend you run the following guide from Atlassian and click the `Tell me more...` link in the `Do you want to run Bitbucket Server as a service?` row in the `Before you begin` section: https://confluence.atlassian.com/bitbucketserver/install-bitbucket-server-on-linux-868976991.html.

#### Optional: Bitbucket Docker installation
If you don't have a host to install Bitbucket on, then you could try running Bitbucket from a docker container. Here is a Docker image found on Docker Hub directly from Atlassian:

https://hub.docker.com/r/atlassian/bitbucket-server/

**NOTE:** We are not associated to the author of the Docker images above and you should use it at your own expense.

### b. Connect Bitbucket to JIRA user server
Now that Bitbucket is ready, we should connect it to JIRA user server to avoid managing user credentials in multiple places. To do so, follow Atlassian's guide below. **Note** that we already did Step 1 earlier after installing JIRA:
* https://confluence.atlassian.com/bitbucketserver/connecting-bitbucket-server-to-jira-for-user-management-776640400.html

### c. Create Application Link with JIRA and Bamboo from Bitbucket
This step is necessary so that JIRA and Bitbucket are aware of each other and so Bitbucket Bamboo can provide JIRA with commit history related to a specific issue. To create an application link with JIRA, do the following steps:

* Click on Cog Ico.
	+ Or open http://${BITBUCKET_IP}:7990/admin in your browser.
* Click on `Application links` under `SETTINGS`
	+ Or open http://${BITBUCKET_IP}:7990/plugins/servlet/applinks/listApplicationLinks in your browser.
* On the text box, enter the URL for JIRA in the format of http://${JIRA_IP}:8080, then click on `Create new link` button.
* On the pop up that shows up, make sure the URLs are correct and check the box that says `The servers have the same set of users and usernames.`, then click on `Continue`.
* You will then be redirected to JIRA and may be asked to enter your admin credentials.
	+ If asked for credentials, enter your admin login credentials and click `Confirm` button.
* Once you are in JIRA, a pop up will come up to ask you to do the application like to Bamboo from the JIRA side
	+ Make sure the information is correct, then click the `Continue` button.
* If all went well, you will be redirected back to Bamboo and will see a dialogue with a green checkmark saying something like `Application Link 'JIRA' created successfully.`

You have successfully make the application link to JIRA. Now follow the same steps for Bamboo using the URL for Bamboo.

## 5. JIRA, Bitbucket, and Bamboo Integration
Now comes the fun part, which is to put all the pieces together into an automated CI/CD workflow that reports to JIRA.

### a. Create Bluecompute Web BLUEWEB Project in JIRA
In order for us to see Bitbucket commit history and Bamboo builds into JIRA, we first need to create a project in JIRA. To do so, do the following:
* Open JIRA in a new browser tab.
* Click on Projects->Create project.
* Select `Scrum software development` on the `Create project` pop up, then click `Next` button.
* On the next window, which shows you a basic `Scrum software development` workflow, click on `Select` button.
* Name the project `Bluecompute Web` and enter `BLUEWEB` for the Key, then click on `Submit` button.

If everything went well, you will now be greeted with the `Backlog` page in the `BLUEWEB board`.

### b. Create a JIRA Issue
To create a JIRA issue, do the following:
* Click on the `Create` button at the top.
* Make sure the `Bluecompute Web (BLUEWEB)` project is selected in the `Project` field.
* Enter `Integration Test` in the `Summary` field.
* Scroll down to the `Assignee` field and click `Assign to me` or select your user in the dropdown.
* Click on `Create` button to finish creating the issue.

If everything went well, you should see your new issue (BLUEWEB-1 Integration Test) listed under `Backlog`. To open the issue to see its details, just click on `BLUEWEB-1` and you will see a side window open on the right side. If that's too small for you, then click on `BLUEWEB-1` on the side window to open a full page view of the issue. You can also get to that view by typing http://${JIRA_IP}:8080/browse/BLUEWEB-1 in your browser address.

Now that everything is done on the JIRA side, let's move on to Bitbucket.

### c. Add your SSH Key to Bitbucket
In order for you to push code to Bitbucket, it will need access to your workstation's SSH key. To create an SSH key or use your existing SSH Key on Bitbucket Server, we recommend you follow Atlassian's guide below:
* https://confluence.atlassian.com/bitbucketserver/ssh-user-keys-for-personal-use-776639793.html

### d. Create the Bluecompute Project in Bitbucket
Now we have to create a Bamboo git repository to push new code changes to so that they show up in JIRA. But first, we must create a Bitbucket project, where the git repository will reside, along with any future repositories. To create a Bitbucket project, do the following:
* Open Bitbucket in a new browser tab.
* Click on `Projects` at the top bar.
* Click on the `Create project` button in the Projects page.
* Fill out the `Create a project` page as follows:
	+ Enter `Bluecompute` in the `Project name` field.
	+ Enter `BLUE` in the `Project key` field.
+ Click `Create project` button.

If all went well, you should be greeted with the `Bluecompute` project page, where it should say `There are no repositories in this project yet`. Now let's create our `bluecompute-web` repository.

### e. Create and Setup bluecompute-web Git Repository on Bitbucket
To create the git repository, do the following:
* On the `Bluecompute` project page in Bitbucket, click the `Create repository` button.
* Enter `bluecompute-web` in the `Name` field in the `Create a repository in Bluecompute` page, then click `Create repository`.

If all went well, you should be greeted with the `bluecompute-web` home page where it should say `You have an empty repository` at the top.

Now we need to clone the `bluecompute-web` repo from GitHub and push it to Bitbucket. To clone the repo, use the following command in your workstation:
```bash
$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web.git
```

Now we can push it to Bitbucket as follows:
```bash
$ cd refarch-cloudnative-bluecompute-web
$ git remote set-url origin ssh://git@${BITBUCKET_IP}:7999/blue/bluecompute-web.git
$ git push -u origin --all
$ git push origin --tags
```

The above commands come from the `My code is already tracked by Git` section in the `bluecompute-web` home page on Bitbucket, where `${BITBUCKET_IP}` is Bitbucket's IP address, which should be shown by the commands in the `bluecompute-web` page.

Once you are done, click the `Refresh` button on Bitbucket, or just simply refresh your browser page.

If all went well, the `bluecompute-web` page will now show all the code from GitHub. Now we can move on to setting Bamboo to automatically trigger a build when a new git commit is pushed to Bitbucket.

### f. Create the Bluecompute Project on Bamboo
Just like in Bitbucket, we need to create a project on Bamboo where the Bluecompute-Web plan will reside. In terms of Bamboo, a `plan` defines everything about your continuous integration build process in Bamboo. For more details on what `projects` and `plans` actually are in Bamboo, checkout their Glossary entries in Bamboo Documentation [here](https://confluence.atlassian.com/bamboo/projects-in-bamboo-289277422.html) and [here](https://confluence.atlassian.com/bamboo/plan-289277457.html).

To create the Bluecompute project in Bamboo, do the following:
* Open Bamboo in a new browser window.
* Click the `Projects` button at the top.
* Assuming no projects exist yet in Bamboo, click on the `Create project` button.
* Fill out the `Create project` page as follows:
	+ Enter `Bluecompute` in the `Project name` field.
	+ Enter `BLUE` in the `Project key` field.
+ Click `Save` button.

If all went well, you should be greeted with the `Bluecompute` project page.

### g. Create the bluecompute-web Plan on Bamboo
The traditional way of creating a plan is to use Bamboo's web interface, where we can manually create a plan that represents a CI/CD pipeline and all of it's stages. This approach works great, but the moment you start adding multiple plans for multiple repositories, it can become error prone.

Instead, we are going to use [`Bamboo Specs`](https://confluence.atlassian.com/bamboo/bamboo-specs-894743906.html) to create the plans programmatically for us from a Bitbucket repository. The idea is to put your CI/CD pipelines and configuration as code to leverage automation and source control versioning to keep track of configuration changes. Atlassian has a great article that explains the benefits of this approach in this [article](https://confluence.atlassian.com/bamboo/bamboo-specs-894743906.html).

There are 2 ways of implementing Java Specs. The first is to use Bamboo Java Specs, which is Bamboo's best feature version of Bamboo specs. Then there is Bamboo YAML Specs, which, though not as mature as Java Specs, it is a much simpler way to get started using Bamboo specs that is programming language agnostic, and it also uses a similar YAML syntax that other great CI/CD services offer. For a more detailed explanation/comparison both Java and YAML specs, take a look at the link [here](https://docs.atlassian.com/bamboo-specs-docs/6.6.1/).

For our purposes, we are going to use the YAML specs to implement the CI/CD build since it is much easier to read and code for than the Java Specs, which are, in my opinion, very verbose. If you want to look for yourself how verbose a Java spec is compared to a YAML spec, take a look at both the Java and YAML specs for `bluecompute-web` repo here:]
* [bluecompute-web Java Specs](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/bamboo-specs/PlanSpec.java)
	+ About 88 lines since the time of writing.
* [bluecompute-web YAML Specs](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/bamboo-specs/bamboo.yaml)
	+ About 30 lines since the time of writing, which is less than half of Java Specs.

Now that the above is out of the way, let's proceed with creating the bluecompute-web plan. To do so, we are going to do 2 things:
* Import the `bluecompute-web` repository.
* Enable Spec Scanning on the `bluecompute-web` repository.
* Enable `bluecompute-web` repository to have access to the Bamboo projects.
* Enable `bluecompute-web` repository to create plans in the `Bluecompute` Bamboo project.

#### i. Import the bluecompute-web repository in Bamboo
To import the bluecompute-web repository in Bamboo, do the following:
* Click Cog Icon-> Linked repositories.
	+ Or go to http://${BAMBOO_IP}:8085/admin/configureLinkedRepositories.action in your browser.
+ Click `Add repository` button.
+ Select `Bitbucket Server / Stash` in the `Repository host` window.
+ Fill out the `Create repository` window as follows:
	+ Enter `bluecompute-web` in the `Name` field.
	+ Select `Bitbucket` in the `Server` dropdown.
	+ Select the `Bluecmopute / bluecompute-web` repository in the `Repository` dropdown.
	+ Select `master` in the `Brach` field.
+ Click the `Save repository` button.

If all went well, you should see a `Repository created successfully.` pop up.

#### ii. Enable Spec Scanning and Project Access for the `bluecompute-web` Repository
Spec Scanning is what allows Bamboo to scan for the YAML Specs inside a Bitbucket repository so that it can automatically create the Build plans upon a new git commit to Bitbucket. To enable Spec Scanning for `bluecompute-web` repository, do the following:
* Click the `bluecompute-web` repository in the `Linked repositories` window.
* Click the `Bamboo Specs` tab.
* Click the toggle button next to `Allow Bamboo to scan this repository for YAML and Java Specs.` to enable Spec Scanning.
	+ If you get a pop up that shows you how to create Bamboo Specs with both Java and YAML exaples, click `Got it` to dismiss it.
* You should see a few sections as soon as you clicked the toggle button.
* Under the `Access` section, tick the box that says `Access all projects`.
* Now click the `Specs status` tab and click the `Scan` button to see if Bamboo is able to get Scan Specs from the `bluecompute-web` repository.
	+ After about 10 seconds or so, you should see a table entry that says `Specs execution successful`, which means Spec Scanning worked as expected.
* To save the above settings changes, click on the `General` tab, then click the `Save repository` button at the bottom.

Now the `bluecompute-web` repository can see the Bamboo projects and is able to create plans, but only on the projects that Bamboo specifically allows it to. The next step will show how to enable Bambo Specs on the `Bluecompute` Bamboo project.

#### iii. Enable bluecompute-web Repository to Create Plans in the Bluecompute Bamboo Project
This is the final configuration test before we are able to run trigger a Bamboo build from Bitbucket and have it report status to JIRA. To allow the `bluecompute-web` Bitbucket repository to create plans in `Bluecompute` Bamboo project, do the following:
* On Bamboo, click the `Projects` and then click the `Bluecompute` project.
	+ Or you can go to http://${BAMBOO_IP}:8085/browse/BLUE on your browser.
* Click on the `Project settings` button.
* Then click on the `Bamboo Specs repositories` button under `Project details`.
* Click the search bar under `Bamboo Specs repositories` and type `bluecompute-web` if it doesn't already auto-populate upon clicking.
* Click on `bluecompute-web` and click the `Add` button.

If all went well, you should see a pop up saying that `bluecompute-web has been added`. This step might have been redundant but it just helps ensure that a plan will be created in the `Bluecompute` project in Bamboo, even if a plan was already created when you enabled Spec Scanning on the previous step and did a test Scan.

Now, after all this reading, you are now ready to kick off you CI/CD pipeline!

## 6. Integration Test
Finally, the moment we have been waiting for. We are going to trigger a CI/CD build on Bamboo from Bitbucket that does the following:
* Checkout the `bluecompute-web` repository.
* Build a new Docker image using the Docker capability in the Bamboo agent.
* Log into ICP's private registry using Global Variables and [ush the Docker image to ICP's private registry.
* Use the Kubernetes capability and access the Kubeconfig file, via Global Variables, to update an existing bluecompute-web deployment on ICP.
* Report build status to JIRA.

On top of that, we Bitbucket commits will also show on JIRA!

### a. Create and Push Test Commit to Trigger the Bamboo Build
To trigger the build, let's start by changing some text in the `bluecompute-web` home page:
```bash
$ cd refarch-cloudnative-bluecompute-web

# On Mac OS
$ sed -i.bak 's/CHECK OUR AWESOME COLLECTIONS/BAMBOO TEST/g' StoreWebApp/public/resources/components/views/home.html

# On Linux
$ sed -i 's/CHECK OUR AWESOME COLLECTIONS/BAMBOO TEST/g' StoreWebApp/public/resources/components/views/home.html

```

If you rather make the change using your text editor, then open the `StoreWebApp/public/resources/components/views/home.html` file and replace the `CHECK OUR AWESOME COLLECTIONS` text with `BAMBOO TEST` or whatever text you want and save the file.

**NOTE:** In order for Bitbucket and Bamboo to report commits and build results to JIRA, we need to include the JIRA issue key in the commit message.

Now commit the file and push it to Bitbucket as follows:
```bash
$ git commit -m "BLUEWEB-1: Integration Test" StoreWebApp/public/resources/components/views/home.html
$ git push origin master
```

This should trigger the Bamboo build.

### b. View Build Status on Bamboo
To see if a plan was created on Bamboo through the git build, do the following:
* Open Bamboo in a browser tab.
* Click Build->All build plans.
	+ Or go to http://${BAMBOO_IP}:8085/allPlans.action on your browser.
* You should see the `Bluecompute Web` with a build number next to it.
* Click the build number, which will take you to the `Build result sumary` page.
* In the `Build result summary` page you should see the `Code commits` that triggered the build along with the `Jira issues` linked to the build.
* On the left side you have the `Stages & jobs` section, which has only 1 stage that's made up of 2 jobs.
	+ The 1st job is the Docker build & push to ICP private registry part.
	+ The 2nd job is the part that updates the Bluecompute Web deployment on ICP.
* Feel free to click on either job to see its results.

### c. View Bamboo Build Results and Bitbucket Commits on JIRA
Now comes the part that will tell if all moving parts are working together as expected. Let's see if JIRA picked up the Bamboo build status and the Bitbucket commits on the `BLUEWEB-1: Integration Test` JIRA issue. To do so, do the following:
* Open JIRA on a browser tab.
* Click on Projects->Bluecompute Web (BLUEWEB)
	+ Or go to http://${JIRA_IP}:8080/projects/BLUEWEB/issues/BLUEWEB-1 in your browser.
* You should see a list of open issues, which in our case should only be the `BLUEWEB-1 Integration Test` issue.
* Click on `BLUEWEB-1`.
	+ Or go to http://${JIRA_IP}:8080/browse/BLUEWEB-1 in your browser
* On the right side under the `Development` section you should see at least `1 commit` and `1 build`, which means that both Bamboo and Bitbucket are reporting to JIRA as expected

### d. Optional: Verify Changes in the Bluecompute Web Home Page on ICP
Last but not least, you should check that the new Docker image was indeed used to update the Bluecompute Web deployment on ICP.

The easiest way to verify is by opening a browser and going to http://${ICP_PROXY_NODE_OR_WORKER_NODE_IP}:31337. If all went well, the home page should display the text `BAMBOO TEST`.

## Conclusion
Congratulations on getting to the end of this document. You have successfully setup a JIRA, Bamboo, and Bitbucket stack to run Automated CICD pipelines to update Kubernetes deployment on ICP!

With this knowledge, you should be able to easily create more CI/CD pipelines that update Kubernetes deployment on ICP from your Atlassian stack. The concepts from this document are easily carried over to other CI/CD services and projects with different programming languages.

With the rate of change of technoly nowadays, it is imperative to adopt these techologies with automation from the start. The beauty of putting the CI/CD configuration in source control is the ability to track its change and evolution with time. Also, in case of emergecies or disaster recoveries, having your configuration as part of source control means that you can be back in business quickly by simply pointing your new CI/CD environment to your source control and doing minimal configuratino steps.

Hopefully you found this document useful and take it for a spin. If you would like to contribute to this document, feel free to fork this project and submit a Pull Request.