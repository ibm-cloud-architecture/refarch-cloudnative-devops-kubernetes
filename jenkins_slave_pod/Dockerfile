FROM ubuntu:16.04

# Install needed packages
RUN apt-get update
RUN apt-get install -y ca-certificates uuid-runtime jq
RUN apt-get install -y curl
ADD https://github.com/mikefarah/yaml/releases/download/1.8/yaml_linux_amd64 /usr/local/bin/yaml
RUN chmod a+x /usr/local/bin/yaml

# Gradle
RUN apt-get install -y gradle

# Java
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install CF CLI
ADD https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.19.0 /tmp/cf-cli.tgz
RUN mkdir -p /usr/local/bin && \
    tar -xzf /tmp/cf-cli.tgz -C /usr/local/bin && \
    cf --version

# Install Bluemix CLI
ADD http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.2_amd64.tar.gz /tmp/bx-cli.tar.gz
RUN cd /tmp/ && \
    tar -xvf bx-cli.tar.gz && \
    cd Bluemix_CLI && \
    ./install_bluemix_cli && \
    bx --version

# Node and NPM
RUN apt-get install -y nodejs
RUN apt-get install -y npm
RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install Docker
RUN apt-get install -y iptables
ADD https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_17.03.1~ce-0~ubuntu-xenial_amd64.deb \
	/tmp/docker.deb
RUN dpkg -i /tmp/docker.deb

# Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# jenkins user
#RUN useradd -m jenkins
#USER jenkins

# Install Kubernetes Container Service plugin
RUN bx plugin install container-service -r Bluemix

# Install Container Rervice plugin
RUN bx plugin install container-registry -r Bluemix

# Install helm
ADD https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get /tmp/get_helm.sh
RUN sh /tmp/get_helm.sh

#USER root

COPY startup.sh startup.sh
ENTRYPOINT ["./startup.sh"]
