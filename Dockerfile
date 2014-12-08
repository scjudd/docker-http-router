FROM ubuntu:trusty
MAINTAINER Spencer Judd <spencercjudd@gmail.com>

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    jq \
    nginx \
 && rm -rf /var/lib/apt/lists/* \
 && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

COPY run.sh /

EXPOSE 80
CMD /run.sh

