#################################################################
# Dockerfile for Zimbra Ubuntu
# Based on Ubuntu 20.04
# Created by Darnel Hunter
#################################################################
#FROM amd64/ubuntu:20.04
FROM ubuntu:20.04

MAINTAINER Darnel Hunter <dhunter@innotel.us>

ARG DEBIAN_FRONTEND=noninteractive

# Update and Upgrade Ubuntu
RUN     apt-get update -y && \
        apt-get upgrade -y && apt-get install sudo -y

# Enable install resolvconf
RUN echo 'resolvconf resolvconf/linkify-resolvconf boolean false' | debconf-set-selections

# Install dependencies
RUN apt-get install -y gcc make g++ openssl libxml2-dev wget nano perl libnet-ssleay-perl libauthen-pam-perl libio-pty-perl unzip shared-mime-info curl cron software-properties-common openjdk-8-jdk ant ant-optional ant-contrib ruby git maven build-essential debhelper lsb-core bind9 bind9utils ssh netcat-openbsd sudo libidn11 libpcre3 libgmp10 libexpat1 libstdc++6 libperl5.30 libperl-dev libaio1 resolvconf unzip pax sysstat sqlite3 dnsutils iputils-ping w3m gnupg less lsb-release rsyslog net-tools vim tzdata wget iproute2 locales curl

# Configure Timezone
RUN echo "tzdata tzdata/Areas select America\ntzdata tzdata/Zones/America select New_York" > /tmp/tz ; debconf-set-selections /tmp/tz; rm /etc/localtime /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

#Install Webmin
RUN cd /usr/src
RUN wget http://download.webmin.com/devel/deb/webmin_current.deb
RUN dpkg -i webmin_current.deb
RUN apt-get -fy install

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Add LC_ALL on .bashrc
RUN echo 'export LC_ALL="en_US.UTF-8"' >> /root/.bashrc
RUN locale-gen en_US.UTF-8

# Download dns-auto.sh
RUN curl -k https://raw.githubusercontent.com/innotelinc/zimbra-docker/master/dns-auto.sh > /usr/src/dns-auto.sh
RUN chmod +x /usr/src/dns-auto.sh

# Copy rsyslog services
RUN curl -k https://raw.githubusercontent.com/innotelinc/zimbra-docker/master/rsyslog > /etc/init.d/rsyslog
RUN chmod +x /etc/init.d/rsyslog

# Crontab for rsyslog
RUN (crontab -l 2>/dev/null; echo "1 * * * * /etc/init.d/rsyslog restart > /dev/null 2>&1") | crontab -

# Startup service
RUN echo 'cat /etc/resolv.conf > /tmp/resolv.ori' > /services.sh
RUN echo 'echo "nameserver 127.0.0.1" > /tmp/resolv.add' >> /services.sh
RUN echo 'cat /tmp/resolv.add /tmp/resolv.ori > /etc/resolv.conf' >> /services.sh
RUN echo '/etc/init.d/bind9 restart' >> /services.sh
RUN echo '/etc/init.d/rsyslog restart' >> /services.sh
RUN echo '/etc/init.d/zimbra restart' >> /services.sh
RUN chmod +x /services.sh

# Entrypoint
ENTRYPOINT /services.sh && /bin/bash
