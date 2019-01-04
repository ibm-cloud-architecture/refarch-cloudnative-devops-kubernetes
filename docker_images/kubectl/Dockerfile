FROM lachlanevenson/k8s-kubectl:latest
RUN apk --no-cache update \
  && apk add --update bash jq ca-certificates curl \
  && update-ca-certificates