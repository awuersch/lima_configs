# This Dockerfile builds NSD
FROM arm64v8/ubuntu:22.10
ARG NSD_VERSION=4.6.1

RUN apt-get update && \
apt-get upgrade -y && \
apt-get install --no-install-recommends -y \
	build-essential \
	libevent-dev \
	libssl-dev \
	wget && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN wget --no-check-certificate "https://nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" && \
	tar zxvf nsd*.tar.gz && \
	cd $(find . -type d -name 'nsd*') && \
	./configure && \
	make && \
	make install && \
	useradd nsd && \
        mkdir -p /usr/local/etc/nsd && \
	chown -R nsd: /usr/local/etc/nsd/ && \
	cd /opt && \
	rm -Rf /opt/nsd*

RUN apt-get purge -y build-essential \
	libevent-dev \
	libssl-dev \
	wget

WORKDIR /usr/local/etc/nsd
# RUN mv nsd.conf nsd.conf.org
# COPY nsd.conf ./

# Ready! Once in a Bash shell you can do 'nsd' then 'dig +noall +answer @127.0.0.1' to see the output of the
# Hello World Python module:
# root@nnn:/usr/local/etc/nsd#: nsd
# root@nnn:/usr/local/etc/nsd#: dig +noall +answer @127.0.0.1
# helloworld.  300 IN A 127.0.0.1
ENTRYPOINT ["/bin/bash"]
