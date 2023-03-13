[[ -z "${LIMA_INSTANCE}" ]] && {
  >&2 echo "env needs LIMA_INSTANCE set and nonempty"
  exit 1
}

export LIMA_GROUP=${LIMA_INSTANCE%[0-9]*}

# This project (git clone)
export WORKSPACE=$HOME/workspace
export WORKSPACE_HOME=$WORKSPACE/home
export VMS=$WORKSPACE/vms

# variables used with both host and vm
export LIMA_GROUP_DIR=lima/$LIMA_GROUP
export LIMA_CIDATA_USER=tony

# host variables
export HOST_WORKDIR=$VMS/$LIMA_GROUP_DIR
export HOST_HOME=$HOST_WORKDIR/home
export HOST_INSTANCE_HOME=$HOST_HOME/$LIMA_INSTANCE
export KUBE_HOST_DIR=$HOST_INSTANCE_HOME/.kube
export KIND_HOST_HOME_DIR=$KUBE_HOST_DIR/kind
# Where to store the VM data like OCI image archives, etc.
export LIMA_DATA_DIR=/opt/lima
export LIMA_HOST_DATA_DIR=$LIMA_DATA_DIR/$LIMA_INSTANCE
# tmp directory
export LIMA_HOST_TMP_DIR=/tmp/lima/$LIMA_INSTANCE

# host variables with fixed names
export LIMA_HOME=$HOST_HOME
export DOCKER_HOST=unix://$HOST_INSTANCE_HOME/docker.sock
export KUBECONFIG=$KUBE_HOST_DIR/config

# vm variables
export VM_WORKDIR=/workdir
export VM_HOME=$VM_WORKDIR/home
export VM_INSTANCE_HOME=$VM_HOME/$LIMA_INSTANCE
export KUBE_VM_DIR=$VM_INSTANCE_HOME/.kube
export KIND_VM_HOME_DIR=$KUBE_VM_DIR/kind
# Where to store the VM data like OCI image archives, etc.
export LIMA_VM_DATA_DIR=/opt/lima

# vm variables with fixed names
export LIMA_WORKDIR=$VM_WORKDIR
export LIMA_DATA_DIR=$LIMA_VM_DATA_DIR

# Lima CLI
# if you manage lima CLI installation with brew
# export LIMACTL_BIN=limactl
# export LIMA_BIN=lima
# if you manage lima CLI installation with the makefile target
export LIMACTL_BIN=$(which limactl)
export LIMA_BIN=$(which lima)

# KinD
#export KIND_NODE_VERSION=v1.24.0
export KIND_NODE_VERSION=v1.26.0

# Registry mirrors
export REGISTRY_IMAGE_TAG="distribution/distribution:2.8.1"
export DOCKERIO_CACHE_NAME='registry-dockerio'
export QUAYIO_CACHE_NAME='registry-quayio'
export GCRIO_CACHE_NAME='registry-gcrio'
export K8SIO_CACHE_NAME='registry-k8sio'
export USDOCKERPKGDEV_CACHE_NAME='registry-us-docker-pkg-dev'
export DOCKERIO_CACHE_DIR=${LIMA_DATA_DIR}/docker-$DOCKERIO_CACHE_NAME
export QUAYIO_CACHE_DIR=${LIMA_DATA_DIR}/docker-$QUAYIO_CACHE_NAME
export GCRIO_CACHE_DIR=${LIMA_DATA_DIR}/docker-$GCRIO_CACHE_NAME
export K8SIO_CACHE_DIR=${LIMA_DATA_DIR}/docker-$K8SIO_CACHE_NAME
export USDOCKERPKGDEV_CACHE_DIR=${LIMA_DATA_DIR}/docker-registry-us-docker.pkg.dev
export DOCKERIO_CACHE_PORT='5030'
export QUAYIO_CACHE_PORT='5010'
export GCRIO_CACHE_PORT='5020'
export USDOCKERPKGDEV_CACHE_PORT='5040'
export K8SIO_CACHE_PORT='5050'
