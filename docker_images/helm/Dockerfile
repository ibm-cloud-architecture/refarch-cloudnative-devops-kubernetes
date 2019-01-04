FROM lachlanevenson/k8s-helm:v2.9.1
RUN apk --no-cache update \
  && apk add --update bash jq ca-certificates curl \
  && update-ca-certificates