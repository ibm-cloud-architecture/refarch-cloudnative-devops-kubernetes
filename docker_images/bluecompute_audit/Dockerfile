FROM alpine

RUN apk add --update ca-certificates
RUN apk add --update bash
RUN apk add --update -t deps curl
RUN rm /var/cache/apk/*

COPY audit_ce_master_install.sh audit_ce_master_install.sh
RUN chmod a+x audit_ce_master_install.sh

CMD bash -C '/audit_ce_master_install.sh'