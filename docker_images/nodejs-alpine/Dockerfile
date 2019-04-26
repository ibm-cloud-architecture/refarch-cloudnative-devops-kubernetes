FROM node:6-alpine
RUN apk --no-cache update \
  && apk add --update bash jq ca-certificates curl openssl \
  && update-ca-certificates
RUN npm -g install jshint