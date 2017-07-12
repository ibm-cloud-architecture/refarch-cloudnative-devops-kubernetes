FROM nimmis/alpine-glibc:latest

# Environment Variables
ENV BX_SPACE ""
ENV BX_API_ENDPOINT api.ng.bluemix.net
ENV BLUEMIX_API_KEY ""

RUN apk add --no-cache bash ca-certificates curl sudo
RUN update-ca-certificates

# Install Bluemix CLI
WORKDIR /tmp
RUN curl -fsSL https://clis.ng.bluemix.net/install/linux | sh
#RUN bx update

RUN mkdir /scripts
ADD /scripts/ /scripts

RUN chmod a+x /scripts/*
