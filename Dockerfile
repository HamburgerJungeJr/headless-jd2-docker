FROM openjdk:11-jre-slim-sid

MAINTAINER PlusMinus <piddlpiddl@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install Windscribe
RUN apt-get update && \
	apt-get -y install --no-install-recommends apt-transport-https ca-certificates debconf-utils iptables expect gnupg gnupg1 gnupg2 gawk && \
	echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-key FDC247B7 && \
	echo 'deb https://repo.windscribe.com/debian buster main' | tee /etc/apt/sources.list.d/windscribe-repo.list && \
	apt-get update && \
	apt-get -y install --no-install-recommends windscribe-cli

# Create directory, and start JD2 for the initial update and creation of config files.
RUN apt-get install -yqq tini ffmpeg wget make gcc jq && \
	mkdir -p /opt/JDownloader/libs && \
	wget -O /opt/JDownloader/JDownloader.jar --user-agent="https://hub.docker.com/r/plusminus/jdownloader2-headless/" http://installer.jdownloader.org/JDownloader.jar && \
	java -Djava.awt.headless=true -jar /opt/JDownloader/JDownloader.jar && \
	mkdir -p /tmp/ && chmod 1777 /tmp &&\
	wget -O /tmp/su-exec.tar.gz https://github.com/ncopa/su-exec/archive/v0.2.tar.gz && \
	cd /tmp/ && tar -xf su-exec.tar.gz && cd su-exec-0.2 && make && cp su-exec /usr/bin &&\
	apt-get purge -yqq wget make gcc && apt-get autoremove -yqq && cd / && rm -rf /tmp/*
	

# Beta sevenzipbindings and entrypoint
COPY common/ /opt/JDownloader/
RUN chmod +x /opt/JDownloader/entrypoint.sh && chmod +x /opt/JDownloader/windscribe.sh

ENTRYPOINT ["/opt/JDownloader/entrypoint.sh"]
# Run this when the container is started
CMD ["java", "-Djava.awt.headless=true", "-jar", "/opt/JDownloader/JDownloader.jar"]
