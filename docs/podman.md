# Using Podman as the CI/CD Container Engine

## Table of Contents
  * [Introduction](#introduction)
  * [Using the Docker-outside-of-Docker (DooD) Approach](#using-the-docker-outside-of-docker-dood-approach)
  * [Using the Docker-in-Docker (DinD) Approach](#using-the-docker-in-docker-dind-approach)
  * [The podman Approach](#the-podman-approach)
    + [Creating a podman Dockerfile](#creating-a-podman-dockerfile)
    + [Building and Testing the podman Container Image](#building-and-testing-the-podman-container-image)
    + [Creating a Jenkins Pipeline with podman Container Image](#creating-a-jenkins-pipeline-with-podman-container-image)
  * [Conclusion](#conclusion)

## Introduction
Podman, as explained in [podman.io](https://podman.io), is a `daemonless container engine for developing, managing, and running OCI Containers on your Linux System`. It's daemonless and self-contained nature already presents a great advantage over the client server approach of Docker, especially on containerized CI/CD pipelines. On top of that, the podman CLI commands are basically the same as Docker. So, adopting podman can be as easy as adding this alias to your shell's RC file:
```bash
alias docker=podman
```

Before diving deep into CI/CD pipelines that use podman, let's dive into how Docker is currently used in containerized CI/CD pipelines today. Docker is the most common container engine to use in a containerized CI/CD pipeline on a Jenkins instance that's deployed in a Kubernetes cluster. There are currently 2 common approaches to using Docker on this scenario. Let's start with the first one.

## Using the Docker-outside-of-Docker (DooD) Approach
This approach describes the use of a `Docker Client` that uses the Kubernetes worker node's Docker socket to build and push images to a registry and also to start test containers. This is the easiest and most common way to use Docker inside of a pipeline because you can leverage the hosts's Docker daemon and avoid having to deploy your own.

The DooD approach presents its challenges because the containers that are created are not managed by Kubernetes, which can result in orphaned containers that can overload the host.

To learn more about the advantages and disadvantages of using the DooD approach, check out the following articles:
* https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/
* https://applatix.com/case-docker-docker-kubernetes-part/

## Using the Docker-in-Docker (DinD) Approach
This approach, though similar to the one above, is different as it encourages you to deploy your own containerized Docker daemon, which is completely separate from the Kubernetes host's Docker Daemon. Optionally, you can deploy a separate Docker Client container that interfaces with the above Docker Daemon directly.

The advantage with this approach is that any container that gets deployed through this Docker daemon gets managed by the same Kubernetes Pod that the Docker Daemon is in. This means that if the pipeline crashes for whatever reason, both the Docker Daemon and the container deployed by the daemon will get killed, thus preventing orphaned containers.

The DinD approach is great for running containers on CI/CD pipelines that are isolated form the rest of the Kubernetes cluster.

Though the DinD approach works great when using Docker Hub as your Docker Registry, the moment you start using a privately hosted registry, you have to do a lot more work to configure the containerized Docker Daemon. For example, you have to setup separate ConfigMaps and Secrets for the registry name and certificates and mount those to the Docker Daemon pod in the Jenkins pipeline, which can result in file system errors with the Jenkinsfile.

To learn more about the advantages and disadvantages of using the DinD approach, check out the following articles:
* https://applatix.com/case-docker-docker-kubernetes-part-2/

## The podman Approach
Using podman in containerized Jenkins pipelines is not that much different than using either the DooD or the DinD approaches. However, here are a couple of advantages over either the DooD or the DinD:
* podman is daemonless, which means that it has a smaller footprint compared to Docker's client-and-server footprint.
* No need to have separate files (i.e. `/etc/docker/daemon.json`) to authorize private registries as it can be done through the podman CLI, which makes the pipeline more portable.

Now let's look at how we can create a simple Dockerfile for podman that we can use in containerized CI/CD pipelines.

### Creating a podman Dockerfile
Creating a podman Dockerfile is a very simple process. First create a file called `Dockerfile`, then enter the following content, and then save it.

```Dockerfile
FROM ubuntu:16.04

RUN apt-get update -qq \
    && apt-get install -qq -y software-properties-common uidmap \
    && add-apt-repository -y ppa:projectatomic/ppa \
    && apt-get update -qq \
    && apt-get -qq -y install podman \
    && apt-get install -y iptables

# Change default storage driver to vfs
RUN sed -i "s/overlay/vfs/g" /etc/containers/storage.conf

# Add docker.io as a search registry
RUN sed -i '0,/\[\]/s/\[\]/["docker.io"]/' /etc/containers/registries.conf
```

Where:
* `ubuntu:16.04` is the base container image.
    + One improvement that can be made here is to use `Alpine Linux` as the base image to obtain an even lighter overall image.
* The first `RUN` statement installs some dependencies, followed by `podman` itself.
* The second `RUN` statement changes the default storage driver to VFS as keeping the default `overlay` will prevent podman from starting inside of a container.
* The last `RUN` statement ads `docker.io` as a search registry.
    + Though optional, this step is useful so that podman searches `docker.io` (or Docker Hub) when using short image names.
    + For example, with the above setup, the `podman pull ubuntu:16.04` command will pull the `docker.io/library/ubuntu:16.04` image.

That's all it takes to create a simple podman Dockerfile. Now let's learn how we can build it and test it.

### Building and Testing the podman Container Image
If you have Docker installed on your workstation, you can try building and running the podman image as follows:

```bash
# CD into the folder containing the Dockerfile
cd /path/to/Dockerfile

# Build the image
docker build -t podman:latest .

# Start the podman container
docker run -it podman:latest bash
```

The above commands build the podman container image, starts a podman container and start a new bash shell to it. Now run the following command to see if you can pull image from Dockerhub directly:

```bash
podman pull ubuntu:16.04
```

If pull is successful, the command above should present you with an output similar to the following:

```bash
Trying to pull docker.io/library/ubuntu:16.04...Getting image source signatures
Copying blob 0c175077525d done
Copying blob 35b42117c431 done
Copying blob ad9c569a8d98 done
Copying blob 293b44f45162 done
Copying config 13c9f12850 done
Writing manifest to image destination
Storing signatures
13c9f1285025c03cfd56a2809973bfec93a6468953c4d0ed70afb1f492f50489
```

Now you are ready to put this into an actual pipeline.

### Creating a Jenkins Pipeline with podman Container Image
First things first, you have to push this image to a Docker Registry that the pipeline can pull the image from. To do so, run the following commands:

```bash
# Tag the podman image to add the registry name namespace
docker tag podman:latest ${REGISTRY}/${NAMESPACE}/podman:latest

# Push the podman image to the registry
docker push ${REGISTRY}/${NAMESPACE}/podman:latest
```

Where `${REGISTRY}` is the registry name/location and `${NAMESPACE}` is the location inside the registry where you are going to place the image.

Now that we have a podman container image, let's examine a simple build-only Jenkinsfile that uses podman to build and push to a registry:

```groovy
// Pod Template
def podLabel = "web"
def cloud = env.CLOUD ?: "kubernetes"
def registryCredsID = env.REGISTRY_CREDENTIALS ?: "registry-credentials-id"
def serviceAccount = env.SERVICE_ACCOUNT ?: "jenkins"

// Pod Environment Variables
def namespace = env.NAMESPACE ?: "default"
def registry = env.REGISTRY ?: "docker.io"
def imageName = env.IMAGE_NAME ?: "ibmcase/bluecompute-web"

/*
  Optional Pod Environment Variables
 */
def helmHome = env.HELM_HOME ?: env.JENKINS_HOME + "/.helm"

podTemplate(label: podLabel, cloud: cloud, serviceAccount: serviceAccount, envVars: [
        envVar(key: 'NAMESPACE', value: namespace),
        envVar(key: 'REGISTRY', value: registry),
        envVar(key: 'IMAGE_NAME', value: imageName)
    ],
    containers: [
        containerTemplate(name: 'podman', image: 'ibmcase/podman:ubuntu-16.04', ttyEnabled: true, command: 'cat', privileged: true)
  ]) {

    node(podLabel) {
        checkout scm

        // Docker
        container(name:'podman', shell:'/bin/bash') {
            stage('Docker - Build Image') {
                sh """
                #!/bin/bash

                # Construct Image Name
                IMAGE=${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.BUILD_NUMBER}

                podman build -t \${IMAGE} .
                """
            }

            stage('Docker - Push Image to Registry') {
                withCredentials([usernamePassword(credentialsId: registryCredsID,
                                               usernameVariable: 'USERNAME',
                                               passwordVariable: 'PASSWORD')]) {
                    sh """
                    #!/bin/bash

                    # Construct Image Name
                    IMAGE=${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.BUILD_NUMBER}

                    podman login -u ${USERNAME} -p ${PASSWORD} ${REGISTRY} --tls-verify=false

                    podman push \${IMAGE} --tls-verify=false
                    """
                }
            }
        }
    }
}
```

Notice above in the `containers` section that we are using the `podman` image that we made publicly available on Docker Hub and called that container `podman`. In the pipeline stages below we are using the `podman` container to run the `podman build`, `podman login`, and `podman push` commands to build and push images to an authenticated Docker registry.

To learn how to setup a simple pipeline using the above Jenkinsfile, feel free to follow the instructions in the link below:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops-kubernetes#create-and-run-a-sample-cicd-pipeline

Make sure that you use the [`jenkins/Jenkinsfile-podman-build.groovy`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/spring/jenkins/Jenkinsfile-podman-build.groovy) Jenkinsfile in the [`refarch-cloudnative-bluecompute-web`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring) git repo.

## Conclusion
Replacing a container engine with another one can seem like a daunting task, but `podman` makes this easier by making its CLI practically identical to that of Docker, making adoption much easier. Also, not having to manage a separate container daemon and the required configuration files makes managing `podman` a breeze when compare to either the DooD or DinD approaches.

Now that you know how to build CI/CD pipelines with `podman` as the container engine, I encourage you to try and build your own pipelines!