FROM docker:18.09-dind
RUN apk --no-cache update \
  && apk add --update bash jq ca-certificates curl openssl \
  && update-ca-certificates