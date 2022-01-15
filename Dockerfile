FROM ubuntu

# Update everything
RUN apt update

# Install AD Tools
RUN apt install -y sssd
RUN apt install -y krb5-user
RUN apt install -y dialog apt-utils

# Install Network Tools
RUN apt install -y iputils-ping

# Open SSH
RUN apt install -y openssh-server

# Extra Tools
RUN apt install -y ansible
RUN apt install -y screen
RUN apt install -y dnsutils
RUN apt install -y nano
RUN apt install -y curl
RUN apt install -y python3-pip
RUN pip3 install azure-cli
RUN apt install -y git
RUN apt install -y iperf3
RUN apt install -y snmp
RUN apt install -y sudo
RUN apt install -y tcpdump

# Copy Scripts and set Permissions
COPY scripts /scripts
RUN chmod -R 700 /scripts

# Run
EXPOSE 22
ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/usr/sbin/sssd","-i"]