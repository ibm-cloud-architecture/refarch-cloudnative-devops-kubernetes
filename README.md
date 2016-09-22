# DevOps for Cloud Native Reference Application

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative*

## Introduction

DevOps, specifically automated Continuous Integration and Continuous Deployment (CI/CD), is important for Cloud Native Microservice style application. This project is developed to demonstrate how to use tools and services available on IBM Bluemix to implement the CI/CD for the BlueCompute reference application.

The project uses [Bluemix DevOps open toolchains](https://new-console.ng.bluemix.net/docs/toolchains/toolchains_overview.html) to implement the CI/CD. The goal is to standup most of the application components as part of an automated pipeline. So you don't have to go through the manual setup as outlined in the project main repository page.

To read more about the Open Toolchains, please check out this [Blog post](https://developer.ibm.com/devops-services/2016/06/16/open-toolchain-with-ibm-bluemix-devops-services/)

Let's get started.

## Setup BlueCompute application using Bluemix DevOps open toolchain

With the open toolchain, you should be able to stand up the entire application stack, including API gateway, Database, computing component, with little manual configuration.

### Prerequisites

You need to have a Bluemix account. Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration)

Once you have logged in, create a new space for hosting the application.

### Step 1:  Provision the API Connect Service

1. Click on the Bluemix console and select API as shown in the figure below. ![API Info](static/imgs/bluemix_1.png?raw=true)
2. Select the API Connect service as shown below. ![API Info](static/imgs/bluemix_2.png?raw=true)
3. Click "Create" in the Getting Started with API Connect page. In API Connect creation page, specify the Service name anything you like or keep the default. Then select the free Essentials plan for this walkthrough.
4. After the API Connect service is created, launch the API Connect service by clicking "Launch API Manager" ![API Info](static/imgs/bluemix_3.png?raw=true)
5.  In the API Manager page, navigate to the API Connect Dashboard and select "Add Catalog" at the top left. You may notice that a
sandbox has automatically been generated for you. ![API Info](static/imgs/bluemix_4.png?raw=true)
6. Name the catalog "**BlueCompute**" and press "Add".
7. Select the catalog and then navigate to the Settings tab and click the Portal sub-tab.
8. To setup a Developer Portal that your consumers can use to explore your API, select the IBM Developer Portal radio button. Then click the "Save" button to top right menu section. This will
provision a portal for you. You should receive a message like the one below. ![API Info](static/imgs/bluemix_9.png?raw=true)
9. Once the new Developer Portal has been created, you will receive an email.

### Step 2: Configure the DevOps open toolchains

The project uses a centralized property file to control the configuration for various endpoint and environment variable. You need to configure them before executing the toolchain.

TODO: Instruction on configuration.

### Step 3: Create the Bluemix DevOps toolchain

Click the following button to deploy the toolchain to Bluemix.

[![Deploy To Bluemix](https://new-console.ng.bluemix.net/devops/graphics/create_toolchain_button.png)](https://new-console.ng.bluemix.net/devops/setup/deploy/?repository=https%3A//github.com/ibm-cloud-architecture/refarch-cloudnative-devops.git)

This button essentially uploads the toolchain template to your Bluemix space. The Bluemix DevOps runtime will parse the template file and creates associated DevOps components for you, such as github repos and delivery pipelines.


### Step 4: Update the toolchain

There are certain credential needs to updated in order to execute the toolchain:

TODO - Provide detail what needs to updated.


### Step 5: Execute the toolchain

TODO - execute the entire toolchain???

### Step 6: Validate the solution

You will need to subscribe the APIs via APIC developerPortal, please follow the instructions below to subscribe:

TODO - Add developerPortal instruction.


## Toolchains in detail

TODO - Quick walkthrough of the individual pipelines within the toolchain
