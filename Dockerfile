FROM centos:6.6

RUN echo 'export TZ="MST"'>> /etc/profile
RUN echo 'export TZ="MST"'>> /etc/bashrc

RUN yum update -y

RUN yum install ntp which openssh dialog curl -y
# Use if you want SSH Capability and enable in entry point
# RUN yum install openssh-clients openssh-server -y

ADD vertica.rpm vertica.rpm

RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
	&& chmod +x /usr/local/bin/gosu

ENV SHELL "/bin/bash"

# Create user dbadmin and configure it
RUN groupadd -r verticadba
RUN useradd -r -m -g verticadba dbadmin
RUN chsh -s /bin/bash dbadmin
RUN chsh -s /bin/bash root
#RUN echo "dbadmin -       nice    0" >> /etc/security/limits.conf
#RUN echo "dbadmin -       nofile  65536" >> /etc/security/limits.conf

# Install vertica by RPM
RUN rpm -ivh vertica.rpm

# Install database - 
RUN /opt/vertica/sbin/install_vertica --license CE --accept-eula --hosts 127.0.0.1 --dba-user-password-disabled --failure-threshold NONE --no-system-configuration

# Create default database
USER dbadmin
RUN /opt/vertica/bin/admintools -t create_db -s localhost -d docker -c /home/dbadmin/docker/catalog -D /home/dbadmin/docker/data  --skip-fs-checks

USER root

# Used for persistent data when defined
ENV VERTICADATA /home/dbadmin/docker
VOLUME  /home/dbadmin/docker

ADD ./verticaStart.sh /
RUN chmod 755 /verticaStart.sh
ENTRYPOINT ["/verticaStart.sh"]
