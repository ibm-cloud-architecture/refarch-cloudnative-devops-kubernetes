FROM lachlanevenson/k8s-helm:v2.3.1

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

ADD https://github.com/mikefarah/yaml/releases/download/1.8/yaml_linux_amd64 /usr/local/bin/yaml
RUN chmod a+x /usr/local/bin/yaml