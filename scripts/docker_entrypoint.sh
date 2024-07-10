#!/bin/ash

CONF_DIR=${HC_WORKDIR:-"/etc/ocserv"}
TCP_PORT=${HC_TCP_PORT:-"443"}
UDP_PORT=${HC_UDP_PORT:-"443"}
OTHER_OPTS=${HC_OTHER_OPTS:-""}
NO_CREATE_DH_PARAMS=${HC_NO_CREATE_DH_PARAMS:-""}
NO_CREATE_SERVER_CERT=${HC_NO_CREATE_SERVER_CERT:-""}
NO_TEST_USER=${HC_NO_TEST_USER:-""}

echo "$(date) [info] The directory with the configuration '${CONF_DIR}' will be used."

if [ ! -d "${CONF_DIR}" ]; then
	echo "$(date) [info] Creating config directory '${CONF_DIR}'..."
	mkdir "${CONF_DIR}" >/dev/null 2>&1
fi

if [ -z "${NO_CREATE_DH_PARAMS}" ] && [ ! -f "${CONF_DIR}/dh.pem" ]; then
	echo "$(date) [info] Generating DH params file..."
	certtool --generate-dh-params --outfile "${CONF_DIR}/dh.pem" >/dev/null 2>&1
else
	echo "$(date) [info] Using existing custom DH params file."
fi

if [ -z "${NO_CREATE_SERVER_CERT}" ]; then
	if [ ! -f "${CONF_DIR}/server-key.pem" ] || [ ! -f "${CONF_DIR}/server-cert.pem" ]; then
		echo "$(date) [info] No certificates were found, creating them from provided or default values"
		# Check environment variables
		if [ -z "$CA_CN" ]; then
			CA_CN="VPN CA"
		fi
		if [ -z "$CA_ORG" ]; then
			CA_ORG="My Organization"
		fi
		if [ -z "$CA_DAYS" ]; then
			CA_DAYS=9999
		fi
		if [ -z "$SRV_CN" ]; then
			SRV_CN="www.example.com"
		fi
		if [ -z "$SRV_ORG" ]; then
			SRV_ORG="My Company"
		fi
		if [ -z "$SRV_DAYS" ]; then
			SRV_DAYS=9999
		fi
		echo "$(date) [info] Generating CA private key..."
		# No certification found, generate one
		certtool --generate-privkey --outfile "${CONF_DIR}/ca-key.pem" >/dev/null 2>&1
		cat > "${CONF_DIR}/ca.tmpl" <<-EOCA
		cn = "$CA_CN"
		organization = "$CA_ORG"
		serial = 1
		expiration_days = $CA_DAYS
		ca
		signing_key
		cert_signing_key
		crl_signing_key
		EOCA
		echo "$(date) [info] Generating CA self signed certificate..."
		certtool --generate-self-signed --load-privkey "${CONF_DIR}/ca-key.pem" --template "${CONF_DIR}/ca.tmpl" --outfile "${CONF_DIR}/ca.pem" >/dev/null 2>&1
		echo "$(date) [info] Generating server private key..."
		certtool --generate-privkey --outfile "${CONF_DIR}/server-key.pem" >/dev/null 2>&1
		cat > "${CONF_DIR}/server.tmpl" <<-EOSRV
		cn = "$SRV_CN"
		organization = "$SRV_ORG"
		expiration_days = $SRV_DAYS
		signing_key
		encryption_key
		tls_www_server
		EOSRV
		echo "$(date) [info] Generating server self signed certificate..."
		certtool --generate-certificate --load-privkey "${CONF_DIR}/server-key.pem" --load-ca-certificate "${CONF_DIR}/ca.pem" --load-ca-privkey "${CONF_DIR}/ca-key.pem" --template "${CONF_DIR}/server.tmpl" --outfile "${CONF_DIR}/server-cert.pem" >/dev/null 2>&1
		rm -rf "${CONF_DIR}/ca.tmpl" >/dev/null 2>&1
		rm -rf "${CONF_DIR}/server.tmpl" >/dev/null 2>&1
	else
		echo "$(date) [info] Using existing certificates in '${CONF_DIR}'"
	fi
else
	echo "$(date) [info] Using existing custom certificates."
fi

# Create a test user
if [ -z "${NO_TEST_USER}" ] && [ ! -f "${CONF_DIR}/ocpasswd" ]; then
	TEST_PASSWORD=$(pwgen -c 10 -n 1 2>/dev/null)
	if [ -n "${TEST_PASSWORD}" ]; then
		echo -n "${TEST_PASSWORD}" | ocpasswd -c "${CONF_DIR}/ocpasswd" test
		echo "$(date) [info] Creating test user 'test' with password '${TEST_PASSWORD}'"
	else
		echo "$(date) [info] Creating test user 'test' with password 'test'"
		echo 'test:*:$5$DktJBFKobxCFd7wN$sn.bVw8ytyAaNamO.CvgBvkzDiFR6DaHdUzcif52KK7' > "${CONF_DIR}/ocpasswd"
	fi
fi

echo "$(date) [info] Enable ipv4 forward..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1

echo "$(date) [info] Enable NAT forwarding, TCP port: $TCP_PORT, UDP port: $UDP_PORT..."
iptables -t nat -A POSTROUTING -j MASQUERADE >/dev/null 2>&1
iptables -A INPUT -p tcp --dport $TCP_PORT -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p udp --dport $UDP_PORT -j ACCEPT >/dev/null 2>&1
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu >/dev/null 2>&1

if ! `test -c /dev/net/tun`; then
	echo "$(date) [info] Enable TUN device..."
	mkdir -p /dev/net >/dev/null 2>&1
	mknod /dev/net/tun c 10 200 >/dev/null 2>&1
	chmod 600 /dev/net/tun >/dev/null 2>&1
fi

# Run server
if [ -f "${CONF_DIR}/ocserv.conf" ]; then
	echo "$(date) [info] Starting server using options '-c ${CONF_DIR}/ocserv.conf ${OTHER_OPTS} $@'..."
	exec ocserv -c "${CONF_DIR}/ocserv.conf" "${OTHER_OPTS}" "$@";
else
	echo "$(date) [warning] Configuration file '${CONF_DIR}/ocserv.conf' not found."
	echo "$(date) [info] Starting server using options '-c /etc/ocserv.default.conf ${OTHER_OPTS} $@'..."
	exec ocserv -c "/etc/ocserv.default.conf" "${OTHER_OPTS}" "$@";
fi
