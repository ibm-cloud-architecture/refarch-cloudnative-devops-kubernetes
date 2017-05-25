FROM alpine

RUN apk --no-cache update \
 && apk add --update bash mysql-client jq

ADD helper.sh /
ADD startup.sh /
ADD load-data.sh /
ADD load-data.sql /

RUN chmod a+x helper.sh
RUN chmod a+x startup.sh
RUN chmod a+x load-data.sh
