

The `install_jenkins.sh` script does the following:
* **Log into Bluemix.**
* **Creates Container Registry Namespace**, which is used by Jenkins Pipelines to push new Docker images for new builds.
* **Set Terminal Context to Kubernetes Cluster.**
* **Initialize Helm Client and Server (Tiller).**
* **Create Config Map,** which the Slave Pods use to know log into Bluemix and Push new Build Images to the private Bluemix Container Registry.
* **Create Secret,** which is needed to authenticate against Bluemix and Container Registry Service.
* **Create Jenkins Persistent Volume Claim,** which is where all Jenkins and build related data is stored and read by Jenkins Master Pods and Slave Pods.
* **Install Jenkins Chart on Kubernetes Cluster using Helm.**

[Bluemix Kubernetes Persistent Volume Claim](https://console.ng.bluemix.net/docs/containers/cs_apps.html#cs_apps_volume_claim)



### Step 2: Enable HTTPS Certificate Validation
In order for the Jenkins master pod to establish and verify a secure connection with the slave pods, you must set the **Kubernetes URL** to `https://10.10.10.1/`. Please follow the steps in the diagram below.

![HTTPS Certificate Check](static/imgs/kubernetes.png?raw=true)  

That's it! You now have a fully working version of Jenkins on your Kubernetes Deployment