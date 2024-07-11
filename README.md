# OpenConnect server (ocserv) docker image (using alpine linux)

[![Docker pulls)](https://img.shields.io/docker/pulls/cherts/ocserv.svg)](https://hub.docker.com/r/cherts/ocserv)
![LICENSE](https://img.shields.io/github/license/cherts/ocserv_docker)

ocerv_docker is an OpenConnect VPN Server boxed in a Docker image built by [Mikhail Grigorev](mailto:sleuthhound@gmail.com)

## What is OpenConnect server?

OpenConnect VPN server is an SSL VPN server that is secure, small, fast and configurable. It implements the OpenConnect SSL VPN protocol and has also (currently experimental) compatibility with clients using the AnyConnect SSL VPN protocol. The OpenConnect protocol provides a dual TCP/UDP VPN channel and uses the standard IETF security protocols to secure it. The OpenConnect client is multi-platform and available [here](https://www.infradead.org/openconnect/). Alternatively, you can try connecting using the official Cisco AnyConnect client (Confirmed working with AnyConnect 4.802045).

- [Homepage](https://www.infradead.org/openconnect/)
- [Documentation](https://ocserv.openconnect-vpn.net/ocserv.8.html)
- [Source](https://gitlab.com/openconnect/ocserv)

## How is this image different from others?

- Uses the latest version of OpenConnect (v1.3.0);
- Strong SSL/TLS ciphers are used (see tls-priorities options);
- Alpine Linux base image is used;
- Easy customization of the image is possible (changing the directory of the configuration file, TCP and UDP ports and additional options for running ocserv through the variables);

## How to use this image

Get the docker image by running the following commands:
```bash
docker pull cherts/ocserv:latest
```

Start an ocserv instance with minimal and secure configuration:

```bash
docker run -ti -d --rm --name ocserv \
	--privileged \
	-p 443:443 -p 443:443/udp \
	cherts/ocserv:latest
```

This will start an instance with the a test user named `test` and generated random password.

To view the generated password, run the command:
```bash
docker logs ocserv | grep "Creating test user"
```

### Environment Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the ocserv the way you like it, here's what you wanna know.

`HC_WORKDIR`, this is the ocserv working directory, include configuration file ocserv.conf, DH params file (dh-params option), certificate files (server-cert and server-key options) and ocpasswd file (auth option).

`HC_TCP_PORT`, this is the ocserv TCP port number (tcp-port option).

`HC_UDP_PORT`, this is the ocserv UDP port number (tcp-port option).

`HC_OTHER_OPTS`, this is the ocserv comand line options.

`HC_CA_CN`, this is the common name used to generate the CA (Certificate Authority).

`HC_CA_ORG`, this is the organization name used to generate the CA.

`HC_CA_DAYS`, this is the expiration days used to generate the CA.

`HC_SRV_CN`, this is the common name used to generate the server certification.

`HC_SRV_ORG`, this is the organization name used to generate the server certification.

`HC_SRV_DAYS`, this is the expiration days used to generate the server certification.

`HC_NO_TEST_USER`, while this variable is set to not empty, the `test` user will not be created. You have to create your own user with password. The default value is to create `test` user with random password.

`HC_NO_CREATE_DH_PARAMS`, while this variable is set to not empty, the DH params file will not be created. You have to create your own DH params file and set path to file into config ocserv (dh-params option). The default value is to generate DH params file automaticaly if not exist.

`HC_NO_CREATE_SERVER_CERT`, while this variable is set to not empty, the server certificate file will not be created. You have to create your own server certificate file and set path to file into config ocserv (server-cert and server-key option). The default value is to generate server certificate file automaticaly if not exist.

The default values of the above environment variables:

|   Variable      |     Default     |
|:---------------:|:---------------:|
|  **HC_WORKDIR** |   /etc/ocserv   |
|  **HC_TCP_PORT**|       443       |
|  **HC_UDP_PORT**|       443       |
|  **HC_CA_CN**   |      VPN CA     |
|  **HC_CA_ORG**  | My Organization |
| **HC_CA_DAYS**  |       9999      |
|  **HC_SRV_CN**  | www.example.com |
| **HC_SRV_ORG**  |    My Company   |
| **HC_SRV_DAYS** |       9999      |

### Running examples

#### Start an instance out of the box with username `test` and random password

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    cherts/ocserv:latest
```

This will start an instance with the a test user named `test` and generated random password.

To view the generated password, run the command:
```bash
docker logs ocserv | grep "Creating test user"
```

#### Start an instance with server name `vpn.myorg.com`, `My Org` and `365` days

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443/tcp -p 443:443/udp \
    -e HC_SRV_CN=vpn.myorg.com \
    -e HC_SRV_ORG="My Org" \
    -e HC_SRV_DAYS=365 \
    cherts/ocserv:latest
```

#### Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e HC_CA_CN="My CA" \
    -e HC_CA_ORG="My Corp" \
    -e HC_CA_DAYS=3650 \
    cherts/ocserv:latest
```

A totally customized instance with both CA and server certification

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e HC_CA_CN="My CA" \
    -e HC_CA_ORG="My Corp" \
    -e HC_CA_DAYS=3650 \
    -e HC_SRV_CN=vpn.myorg.com \
    -e HC_SRV_ORG="My Org" \
    -e HC_SRV_DAYS=365 \
    cherts/ocserv:latest
```

#### Start an instance as above but without test user

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e HC_CA_CN="My CA" \
    -e HC_CA_ORG="My Corp" \
    -e HC_CA_DAYS=3650 \
    -e HC_SRV_CN=vpn.myorg.com \
    -e HC_SRV_ORG="My Org" \
    -e HC_SRV_DAYS=365 \
    -e HC_NO_TEST_USER=1 \
    -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd \
    cherts/ocserv:latest
```

**WARNING:** The ocserv requires the ocpasswd file to start, if `HC_NO_TEST_USER=1` is provided, there will be no ocpasswd created, which will stop the container immediately after start it. You must specific a ocpasswd file pointed to `/etc/ocserv/ocpasswd` by using the volume argument `-v` by docker as demonstrated above.

#### Start an instance as above but use docker compose

```bash
mkdir ~/ocserv
curl -s -L https://raw.githubusercontent.com/CHERTS/ocserv_docker/master/deploy/docker-compose.yaml -o ~/ocserv/docker-compose.yaml
cd ~/ocserv
docker-compose up -d
```

### User operations

All the users opertaions happened while the container is running. If you used a different container name other than `ocserv`, then you have to change the container name accordingly.

#### Add user

If say, you want to create a user named `jerry`, type the following command

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd jerry
Enter password:
Re-enter password:
```

When prompt for password, type the password twice, then you will have the user with the password you want.

#### Delete user

Delete user is similar to add user, just add another argument `-d` to the command line

```bash
docker exec -ti ocserv ocpasswd -c /etc/ocserv/ocpasswd -d test
```

The above command will delete the default user `test`, if you start the instance without using environment variable `HC_NO_TEST_USER`.

#### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.

#### View ocserv status

Use occtl in contaner for show status

```bash
docker exec -ti ocserv occtl show status
```

You can also use other commands in the occtl utility.

## Build custom image

```
git clone https://github.com/CHERTS/ocserv_docker.git
cd ocserv_docker
_customize_this_image_
./build.sh
```

