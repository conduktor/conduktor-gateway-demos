FROM centos:centos8

# 0. Configure centos repos
# Required to avoid the following error:
# Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: No URLs in mirrorlist

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# 1. Installing Kerberos server, admin and client
RUN yum install -y krb5-server krb5-libs 
RUN yum install -y krb5-workstation krb5-libs 
RUN yum install -y nmap-ncat

# 2. Configuring Kerberos and KDC
COPY krb5.conf /etc/krb5.conf
RUN mkdir /var/log/kerberos
RUN mkdir /etc/kdc
RUN mkdir -p /var/kerberos/krb5kdc/ 
#RUN ln -s /etc/krb5.conf /etc/kdc/krb5.conf

EXPOSE 88

RUN kdb5_util -P conduktor -r TEST.CONDUKTOR.IO create -s

CMD /usr/sbin/krb5kdc -n