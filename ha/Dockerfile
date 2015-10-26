FROM haproxy:1.5
MAINTAINER Laurent Prevost <laurent.prevost@heig-vd.ch>

RUN apt-get update && apt-get -y install wget curl vim rsyslog && apt-get clean

COPY scripts/ /scripts/

RUN chmod +x /scripts/*.sh

COPY config/ /config/

RUN ln -s /config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
RUN ln -s /config/rsyslogd.cfg /etc/rsyslog.d/49-haproxy.conf

CMD [ "/scripts/run.sh" ]