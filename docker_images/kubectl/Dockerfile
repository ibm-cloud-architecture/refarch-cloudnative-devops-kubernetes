FROM alpine

ENV KUBE_LATEST_VERSION="v1.10.3"

RUN apk add --no-cache --update ca-certificates curl jq 

ADD https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/kubectl 
