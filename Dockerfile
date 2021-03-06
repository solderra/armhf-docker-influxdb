FROM armhfbuild/golang:1.4.3
MAINTAINER Florian Barth

ENV DEBIAN_FRONTEND noninteractive

ENV INFLUXDB_VERSION 0.11.1

RUN apt-get update \
	&& apt-get install -y git \
	&& apt-get clean \
	&& rm -rf /etc/apt/lists/*

# Build InfluxDB from source
RUN mkdir -p $GOPATH/src/github.com/influxdata \
	&& cd $GOPATH/src/github.com/influxdata \
	&& git clone https://github.com/influxdata/influxdb \
	&& cd influxdb \
	&& git checkout tags/v${INFLUXDB_VERSION} \
	# go get -u sometime fails first time, but succeeds second time
	# (see https://github.com/golang/go/issues/9224)
	# therefore, we try it a second time, if it failed the first time
	&& ( go get -u -f ./... || go get -u -f ./... ) \
	&& go build ./... \
	&& mv $GOPATH/bin/* /usr/bin \
	&& rm -rf $GOPATH/*
	
COPY types.db /usr/share/collectd/types.db
COPY config.toml /etc/influxdb/config.toml
COPY run.sh /run.sh
RUN chmod +x /*.sh

ENV PRE_CREATE_DB **None**
ENV SSL_SUPPORT **False**
ENV SSL_CERT **None**

# Admin server WebUI
EXPOSE 8083

# HTTP API
EXPOSE 8086

# Raft port (for clustering, don't expose publicly!)
#EXPOSE 8090

# Protobuf port (for clustering, don't expose publicly!)
#EXPOSE 8099

VOLUME ["/var/lib/influxdb"]

CMD ["/run.sh"]
