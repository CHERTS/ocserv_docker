FROM alpine:3.20

ARG HC_VERSION=1.3.0
ARG HC_WORKDIR="/etc/ocserv"
ARG HC_TCP_PORT="443"
ARG HC_UDP_PORT="443"
ARG HC_OTHER_OPTS=""
ENV HC_VERSION $HC_VERSION
ENV HC_WORKDIR $HC_WORKDIR
ENV HC_TCP_PORT $HC_TCP_PORT
ENV HC_UDP_PORT $HC_TCP_PORT
ENV HC_OTHER_OPTS $HC_OTHER_OPTS

MAINTAINER Mikhail Grigorev <sleuthhound@gmail.com>

RUN buildDeps=" \
		g++ \
		gpgme \
		make \
		tar \
		xz \
		gnutls-dev \
		curl-dev \
		cjose-dev \
		http-parser-dev \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		libmaxminddb-dev \
		oath-toolkit-dev \
		freeradius-client-dev \
		krb5-dev \
		protobuf-c-compiler \
		readline-dev \
	"; \
	set -x \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& wget -O ocserv.tar.xz "ftp://ftp.infradead.org/pub/ocserv/ocserv-$HC_VERSION.tar.xz" \
	&& wget -O ocserv.tar.xz.sig "ftp://ftp.infradead.org/pub/ocserv/ocserv-$HC_VERSION.tar.xz.sig" \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm -rf ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure --enable-oidc-auth \
	&& make -j"$(nproc)" \
	&& make install \
	&& mkdir -p $HC_WORKDIR \
	&& cd \
	&& rm -fr /usr/src/ocserv \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv /usr/local/sbin/ocserv-worker /usr/local/bin/occtl /usr/local/bin/ocpasswd \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables libnl3 readline pwgen \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/* \
	&& ocserv --version

COPY config/ocserv.conf $HC_WORKDIR/ocserv.conf
COPY scripts/docker_entrypoint.sh /bin
COPY scripts/ocuser /usr/local/sbin/ocuser
RUN chmod 644 $HC_WORKDIR/ocserv.conf
RUN set -x \
        touch $HC_WORKDIR/ocpasswd \
		&& chmod +x /bin/docker_entrypoint.sh \
		&& chmod +x /usr/local/sbin/ocuser \
		&& sed -i "s@tcp-port.*@tcp-port = $HC_TCP_PORT@g" $HC_WORKDIR/ocserv.conf \
		&& sed -i "s@udp-port.*@udp-port = $HC_UDP_PORT@g" $HC_WORKDIR/ocserv.conf \
		&& sed -i "s@\/etc\/ocserv@$HC_WORKDIR@g" $HC_WORKDIR/ocserv.conf

WORKDIR $HC_WORKDIR

EXPOSE $HC_TCP_PORT/tcp
EXPOSE $HC_UDP_PORT/udp

ENTRYPOINT ["/bin/docker_entrypoint.sh"]
CMD ["-f"]
