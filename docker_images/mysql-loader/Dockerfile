FROM alpine

RUN apk add --update bash \
 && apk add --update mysql mysql-client \
 && rm /var/cache/apk/*

ADD https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 /usr/local/bin/jq
RUN chmod a+x /usr/local/bin/jq

ADD startup.sh /
ADD load-data.sh /
ADD load-data.sql /

RUN chmod a+x startup.sh
RUN chmod a+x load-data.sh