FROM alpine

# bash
RUN apk add --update bash jq curl ca-certificates openssl

# kubectl
# From https://github.com/lachie83/k8s-kubectl/blob/master/Dockerfile
ENV KUBE_LATEST_VERSION="v1.12.4"

RUN apk add --update ca-certificates \
 && apk add --update -t deps \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps

# helm
# From https://github.com/alpine-docker/helm/blob/master/Dockerfile
ARG VERSION=2.9.1

ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV TAR_FILE="helm-v${VERSION}-linux-amd64.tar.gz"

RUN apk add --update --no-cache && \
    curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf linux-amd64 && \
    rm /var/cache/apk/*

# cloudctl
# From https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.2/manage_cluster/install_cli.html
ADD cloudctl /usr/local/bin/cloudctl
RUN chmod +x /usr/local/bin/cloudctl

# mcmctl
# From https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/mcm/installing/install.html#install_cli
ADD mcmctl /usr/local/bin/mcmctl
RUN chmod +x /usr/local/bin/mcmctl