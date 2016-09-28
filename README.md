# DevOps for Cloud Native Reference Application

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative*

## Introduction

DevOps, specifically automated Continuous Integration and Continuous Deployment (CI/CD), is important for Cloud Native Microservice style application. This project is developed to demonstrate how to use tools and services available on IBM Bluemix to implement the CI/CD for the BlueCompute reference application.

The project uses [Bluemix DevOps open toolchains](https://new-console.ng.bluemix.net/docs/toolchains/toolchains_overview.html) to implement the CI/CD. The goal is to standup most of the application components as part of an automated pipeline. So you don't have to go through the manual setup as outlined in the project main repository page. The toolchain for BlueCompute application looks like this:

![DevOps Toolchain](static/imgs/bluemix_devops_toolchain.png?raw=true)  

To read more about the Open Toolchains, please check out this [Blog post](https://developer.ibm.com/devops-services/2016/06/16/open-toolchain-with-ibm-bluemix-devops-services/)

Let's get started.

## Setup BlueCompute application using Bluemix DevOps open toolchain

With the open toolchain, you should be able to stand up the entire application stack, including API gateway, Database, computing component, with little manual configuration.

### Prerequisites

You need to have a Bluemix account. Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration)

Once you have logged in, create a new space for hosting the application.

### Step 1:  Provision the API Connect Service

1. Click on the Bluemix console and select API.  
2. Select the API Connect service.  
3. Click "Create" in the Getting Started with API Connect page. In API Connect creation page, specify the Service name for example cloudnative-apic-service. Then select the Essentials plan for this walkthrough.
4. After the API Connect service is created, launch the API Connect service.  
5. In the API Manager page, navigate to the API Connect Dashboard and select "Add Catalog" at the top left. You may notice that a sandbox has automatically been generated for you.  
6. Name the catalog "**BlueCompute**" and press "Add".
7. Select the catalog and then navigate to the Settings tab and click the Portal sub-tab.
8. To setup a Developer Portal that your consumers can use to explore your API, select the IBM Developer Portal radio button. Then click the "Save" button to top right menu section. This will
provision a portal for you. You should receive a message like the one below. ![API Info](static/imgs/bluemix_9.png?raw=true)
9. Once the new Developer Portal has been created, you will receive an email.

### Step 2: Create the Bluemix DevOps toolchain
[TODO: add images - steps 2-4 documentation in progress]
Click the following button to deploy the toolchain to Bluemix.

[![Create BlueCompute Deployment Toolchain](https://new-console.ng.bluemix.net/devops/graphics/create_toolchain_button.png)](https://new-console.ng.bluemix.net/devops/setup/deploy/?repository=https%3A//github.com/ibm-cloud-architecture/refarch-cloudnative-devops.git)

This button essentially uploads the toolchain template to your Bluemix space. The Bluemix DevOps runtime will parse the template file and creates associated DevOps components for you, such as github repos and delivery pipelines.

### Step 3: Create the toolchain

There are certain credential needs to updated in order to execute the toolchain:
1. Enter toolchain name in the **Name:** field.
2. By default, the **GitHub** integration is configured to clone all git repos to your github account.
3. Click on **Delivery Pipeline** configuration.
4. Enter the Region, Organization, and Space. Adjust the Domain name and APIC hostname to match your region. Also enter APIC Username and Password. Click **Create** to create the toolchain.
5. Click on **View Toolchain** to go to the toolchain page.

This toolchain will create and integrate eight GitHub repos with Issues enabled, and eight Delivery Pipelines each connected to one GitHub repo. Configuration data is shared between all the delivery pipelines.

### Step 4: Execute the toolchain
1. Click on **inventorydb-mysql** delivery pipeline, and click the play button on BUILD stage to initiate the build and deployment of MySQL container. Ensure both the BUILD and DEPLOY stages have completed successfully. If a stage fails, troubleshoot based on the log information.
2. Start BUILD stages for following delivery pipelines in the following sequence making sure each pipeline deployed successfully; **netflix-eureka**, **netflix-zuul**, **micro-inventory**, and **micro-socialreview**.


### Step 5: Complete the solution

After successfully execute all the DevOps pipelines, you have the entire BlueCompute backend ready on IBM Cloud. There are 3 tasks remaining to get the BlueCompute application (both Mobile and Web) working:

- Subscribe to the APIs via API Connect developerPortal.  
   Please follow reference [the API subscription manual](https://github.com/ibm-cloud-architecture/refarch-cloudnative-api#subscribe-to-the-apis-in-the-developer-portal) to subscribe and consume the APIs.   

- Configure and Run the Mobile iOS BlueCompute App.  
   Please follow the [Run the iOS application guide](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-mobile) to setup your iOS application.  

- Configure and Run the BlueCompute Web application.  
   Please follow the [Run the BlueCompute web app](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web) to setup the Web application in IBM Cloud.  

You have set up the BlueCompute stack using IBM Bluemix DevOps open toolchains. 
