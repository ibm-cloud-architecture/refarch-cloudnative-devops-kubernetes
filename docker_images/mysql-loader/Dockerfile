FROM alpine

RUN apk --no-cache update \
 && apk add --update bash mysql-client jq wget ca-certificates \
 && update-ca-certificates

ADD helper.sh /
ADD startup.sh /

RUN chmod a+x helper.sh
RUN chmod a+x startup.sh

ENTRYPOINT [ "/startup.sh" ]
