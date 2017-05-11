FROM alpine

ENV KUBE_LATEST_VERSION="v1.6.2"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && apk add --update bash \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

ADD https://github.com/mikefarah/yaml/releases/download/1.8/yaml_linux_amd64 /usr/local/bin/yaml
RUN chmod a+x /usr/local/bin/yaml