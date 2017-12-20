FROM alpine

RUN apk --no-cache update \
 && apk add --update bash mysql-client jq wget ca-certificates curl \
 && update-ca-certificates

ADD helper.sh /
ADD startup.sh /
ADD https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/master/mysql/scripts/load-data.sql /

RUN chmod a+x helper.sh
RUN chmod a+x startup.sh

ENTRYPOINT [ "/startup.sh" ]
