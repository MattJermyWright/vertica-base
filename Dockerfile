FROM ubuntu:latest

RUN echo 'export TZ="MST"'>> /etc/profile
RUN echo 'export TZ="MST"'>> /etc/bashrc
RUN echo 'export LANG="en_US.UTF-8"' >> /etc/profile
RUN echo 'export LANG="en_US.UTF-8"' >> /etc/bashrc

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y ntp openssh-client openssh-server dialog curl locales

RUN apt-get install -y openssl libssl-dev

ADD vertica-9.deb vertica.deb

#RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.10/gosu' \
#	&& chmod +x /usr/local/bin/gosu

ENV GOSU_VERSION 1.10
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

ENV SHELL "/bin/bash"
ENV LANG en_US.UTF-8
# Fix locales
RUN locale-gen "en_US.UTF-8"

# Create user dbadmin and configure it
RUN groupadd -r verticadba
RUN useradd -r -m -g verticadba dbadmin
RUN chsh -s /bin/bash dbadmin
RUN chsh -s /bin/bash root
#RUN echo "dbadmin -       nice    0" >> /etc/security/limits.conf
#RUN echo "dbadmin -       nofile  65536" >> /etc/security/limits.conf

# Install vertica by DEB file
RUN dpkg -i vertica.deb
RUN apt-get install -fy

# Install database -
RUN ["/bin/bash","-l","-c","/opt/vertica/sbin/install_vertica --license CE --accept-eula --hosts 127.0.0.1 --dba-user-password-disabled --failure-threshold NONE --no-system-configuration"]

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
