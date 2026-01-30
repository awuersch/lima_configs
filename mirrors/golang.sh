#! /usr/bin/env bash
set -euf -o pipefail

# verify golang install

# dirs
rootdir=/root
localdir=/usr/local
godir=${localdir}/go
gobindir=${godir}/bin
rootgodir=${rootdir}/go
rootgobindir=${rootgodir}/bin
rootgosrcdir=${rootgodir}/src

# other
arch=amd64
GOPATH=${rootgodir}
GOBIN=${rootgobindir}
GOSRC=${rootgosrcdir}
GOSUMDB=sum.golang.org

# versions for go and go installs
GO_VERSION=1.25.6
JB_VERSION=0.6.0
JSONNET_VERSION=0.21.0
YQ_VERSION=4.48.1

# apt prep
export DEBIAN_FRONTEND=noninteractive
apt-get -yqq update
apt-get -yqq upgrade

# apt installs
apt-get -yqq install --no-install-recommends ca-certificates curl
update-ca-certificates

# download and install golang
curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz |\
 tar -C ${localdir} -xzf -

>&2 echo "golang is downloaded and installed"

# install go tools
mkdir -p $GOPATH
mkdir -p $GOBIN $GOSRC
PATH="${gobindir}:$PATH"

go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v${JB_VERSION}
go install github.com/google/go-jsonnet/cmd/jsonnet@v${JSONNET_VERSION}
go install github.com/mikefarah/yq/v4@v${YQ_VERSION}

>&2 echo "go tools are installed locally"

cat >> ~/.bashrc <<EOF

# local go path added
export PATH=$GOBIN:$PATH
EOF

>&2 echo "PATH is updated for local go tools"
