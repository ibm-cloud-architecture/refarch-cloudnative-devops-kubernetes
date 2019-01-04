FROM docker:18.06.1-ce
RUN apk --no-cache update \
  && apk add --update bash jq ca-certificates curl openssl \
  && update-ca-certificates