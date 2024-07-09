#!/bin/bash

HCONNECT_WORK_DIR="/etc/ocserv"
HCONNECT_INFO=(
    "cherts/ocserv,1.3.0"
)

# Check command exist function
_command_exists() {
    type "$1" &> /dev/null
}

if _command_exists docker; then
    DOCKER_BIN=$(which docker)
else
    echo "ERROR: Command 'docker' not found."
    exit 1
fi

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "** Trapped CTRL-C"
    exit 1
}

#${DOCKER_BIN} login -u XXXXX -p YYYYY

for DATA in ${HCONNECT_INFO[@]}; do
	IMAGE_NAME=$(echo "${DATA}" | awk -F',' '{print $1}')
	IMAGE_VER=$(echo "${DATA}" | awk -F',' '{print $2}')
	echo "Docker remove old image '${IMAGE_NAME}:${IMAGE_VER}'..."
	${DOCKER_BIN} rmi ${IMAGE_NAME}:${IMAGE_VER}
	echo "Docker build image '${IMAGE_NAME}:${IMAGE_VER}'..."
	${DOCKER_BIN} build -t ${IMAGE_NAME}:${IMAGE_VER} --no-cache --progress=plain --build-arg HC_VERSION=${IMAGE_VER} --build-arg HC_WORKDIR=${HCONNECT_WORK_DIR} -f Dockerfile .
	if [ $? -eq 0 ]; then
		echo "Done build image."
		#echo "Docker push image '${IMAGE_NAME}:${IMAGE_VER}'..."
		#${DOCKER_BIN} push ${IMAGE_NAME}:${IMAGE_VER}
	else
		echo "ERROR: Failed build image '${IMAGE_NAME}:${IMAGE_VER}'"
		exit 1
	fi
done
