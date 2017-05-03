FROM nimmis/alpine-glibc:latest

# Environment Variables
ENV BX_SPACE ""
ENV BX_API_ENDPOINT api.ng.bluemix.net
ENV BLUEMIX_API_KEY ""

RUN apk add --no-cache bash ca-certificates curl
RUN update-ca-certificates

# Install Bluemix CLI
WORKDIR /tmp
RUN curl -o /tmp/Bluemix_CLI.tar.gz http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.2_amd64.tar.gz && \
  tar zxvf Bluemix_CLI.tar.gz && \
  Bluemix_CLI/install_bluemix_cli && \
  rm -f /tmp/Bluemix_CLI.tar.gz && \
  rm -rf /tmp/Bluemix_CLI 
WORKDIR /

RUN bx update

RUN mkdir /scripts
ADD /scripts/ /scripts

RUN chmod a+x /scripts/*