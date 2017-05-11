FROM ibmcase/kubectl:latest

ADD config.yaml /
ADD secret.yaml /
ADD create_config_map.sh /
ADD create_secret.sh /

RUN chmod a+x create_config_map.sh
RUN chmod a+x create_secret.sh