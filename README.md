# OpenConnect server (ocserv) docker image (using alpine linux)

[![Docker pulls)](https://img.shields.io/docker/pulls/cherts/ocserv.svg)](https://hub.docker.com/r/cherts/ocserv)
![LICENSE](https://img.shields.io/github/license/cherts/ocserv_docker)

ocerv_docker is an OpenConnect VPN Server boxed in a Docker image built by [mailto:sleuthhound@gmail.com](Mikhail Grigorev)

## What is OpenConnect server?

OpenConnect VPN server is an SSL VPN server that is secure, small, fast and configurable. It implements the OpenConnect SSL VPN protocol and has also (currently experimental) compatibility with clients using the AnyConnect SSL VPN protocol. The OpenConnect protocol provides a dual TCP/UDP VPN channel and uses the standard IETF security protocols to secure it. The OpenConnect client is multi-platform and available [here](https://www.infradead.org/openconnect/). Alternatively, you can try connecting using the official Cisco AnyConnect client (Confirmed working with AnyConnect 4.802045).

- [Homepage](https://www.infradead.org/openconnect/)
- [Documentation](https://ocserv.openconnect-vpn.net/ocserv.8.html)
- [Source](https://gitlab.com/openconnect/ocserv)

## How is this image different from others?

- Uses the latest version of OpenConnect (v1.3.0);
- Strong SSL/TLS ciphers are used (see tls-priorities options);
- Alpine Linux base image is used;
- Easy customization of the image is possible (changing the directory of the configuration file, TCP and UDP ports and additional options for running ocserv through the variables HC_WORKDIR, HC_TCP_PORT, HC_UDP_PORT and HC_OTHER_OPTS);

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

`CA_CN`, this is the common name used to generate the CA (Certificate Authority).

`CA_ORG`, this is the organization name used to generate the CA.

`CA_DAYS`, this is the expiration days used to generate the CA.

`SRV_CN`, this is the common name used to generate the server certification.

`SRV_ORG`, this is the organization name used to generate the server certification.

`SRV_DAYS`, this is the expiration days used to generate the server certification.

`NO_TEST_USER`, while this variable is set to not empty, the `test` user will not be created. You have to create your own user with password. The default value is to create `test` user with random password.

The default values of the above environment variables:

|   Variable   |     Default     |
|:------------:|:---------------:|
|  **CA_CN**   |      VPN CA     |
|  **CA_ORG**  | My Organization |
| **CA_DAYS**  |       9999      |
|  **SRV_CN**  | www.example.com |
| **SRV_ORG**  |    My Company   |
| **SRV_DAYS** |       9999      |

### Running examples

1. Start an instance out of the box with username `test` and random password

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

2. Start an instance with server name `vpn.myorg.com`, `My Org` and `365` days

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e SRV_CN=vpn.myorg.com \
    -e SRV_ORG="My Org" \
    -e SRV_DAYS=365 \
    cherts/ocserv:latest
```

3. Start an instance with CA name `My CA`, `My Corp` and `3650` days

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e CA_CN="My CA" \
    -e CA_ORG="My Corp" \
    -e CA_DAYS=3650 \
    cherts/ocserv:latest
```

A totally customized instance with both CA and server certification

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e CA_CN="My CA" \
    -e CA_ORG="My Corp" \
    -e CA_DAYS=3650 \
    -e SRV_CN=vpn.myorg.com \
    -e SRV_ORG="My Org" \
    -e SRV_DAYS=365 \
    cherts/ocserv:latest
```

4. Start an instance as above but without test user

```bash
docker run -ti -d --rm --name ocserv \
    --privileged \
    -p 443:443 -p 443:443/udp \
    -e CA_CN="My CA" \
    -e CA_ORG="My Corp" \
    -e CA_DAYS=3650 \
    -e SRV_CN=vpn.myorg.com \
    -e SRV_ORG="My Org" \
    -e SRV_DAYS=365 \
    -e NO_TEST_USER=1 \
    -v /some/path/to/ocpasswd:/etc/ocserv/ocpasswd \
    cherts/ocserv:latest
```

**WARNING:** The ocserv requires the ocpasswd file to start, if `NO_TEST_USER=1` is provided, there will be no ocpasswd created, which will stop the container immediately after start it. You must specific a ocpasswd file pointed to `/etc/ocserv/ocpasswd` by using the volume argument `-v` by docker as demonstrated above.

5. Start an instance as above but use docker compose

```bash
mkdir ~/ocserv; cd ~/ocserv
curl -s -L https://raw.githubusercontent.com/CHERTS/ocserv_docker/master/deploy/docker-compose.yaml -o docker-compose.yaml
curl -s -L https://raw.githubusercontent.com/CHERTS/ocserv_docker/master/deploy/ocpasswd -o ocpasswd
-- Edit file docker-compose.yaml and ocpasswd after downloaads
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

The above command will delete the default user `test`, if you start the instance without using environment variable `NO_TEST_USER`.

#### Change password

Change password is exactly the same command as add user, please refer to the command mentioned above.

## Build custom image

```
git clone https://github.com/CHERTS/ocserv_docker.git
cd ocserv_docker
_customize_this_image_
./build.sh
```

