FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

EXPOSE 3128
VOLUME /data

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y squid-openssl
