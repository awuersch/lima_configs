#! /usr/bin/env bash
set -euf

# the magic command for apt ...
function geturis { # pkgver
  local pkgver=$1
  apt-get -yqq install --no-install-recommends --print-uris $pkgver
}

# the magic command for pypi
function getvers { # pkgver
  local pkgver=$1
  pipgrip $pkgver
}

# apt priming
MOUNTS=/mnt
MANIFESTS=$MOUNTS/manifests
STORAGE=/mnt/archive

# dirs
sharedir=/usr/share
keyringsdir=${sharedir}/keyrings
aptdir=/etc/apt
aptsources=${aptdir}/sources.list.d
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
PATH="${gobindir}:$PATH"

# versions for go and go installs
GO_VERSION=1.25.6
JB_VERSION=0.6.0
JSONNET_VERSION=0.21.0
YQ_VERSION=4.48.1

LISTS=$STORAGE/lists
APTS=$LISTS/apt
PYPIS=$LISTS/pypi
RAWS=$LISTS/raw

mkdir -p $APTS/uris
mkdir -p $PYPIS/json
mkdir -p $RAWS

export DEBIAN_FRONTEND=noninteractive

# add apt repositories
#
hashicorpurl=https://apt.releases.hashicorp.com
hashicorpgpg=${keyringsdir}/hashicorp-archive-keyring.gpg
curl ${hashicorpurl}/gpg | gpg --dearmor -o ${hashicorpgpg}
echo "deb [arch=${arch} signed-by=${hashicorpgpg}] ${hashicorpurl} bookworm main" > ${aptsources}/hashicorp.list
#
cloudfoundryurl=https://packages.cloudfoundry.org/debian
cloudfoundrykey=${cloudfoundryurl}/cli.cloudfoundry.org.key
cloudfoundrygpg=${keyringsdir}/cloudfoundry-keyring.gpg
curl ${cloudfoundrykey} | gpg --dearmor -o ${cloudfoundrygpg}
echo "deb [arch=${arch} signed-by=${cloudfoundrygpg}] ${cloudfoundryurl} stable main" > ${aptsources}/cloudfoundry.list
#
apt-get -yqq update
apt-get -yqq install --no-install-recommends ca-certificates
update-ca-certificates
apt-get -yqq upgrade
#
TZ=UTC
echo $TZ > /etc/timezone
# ".tsv" files are per-line tab-separated values with a header line on top
# get package version metadata (avoiding header line by using tail +2)

# download and install go
curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -C ${localdir} -xzf -
# install go tools
mkdir -p $GOPATH
mkdir -p $GOBIN $GOSRC
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v${JB_VERSION}
go install github.com/google/go-jsonnet/cmd/jsonnet@v${JSONNET_VERSION}
go install github.com/mikefarah/yq/v4@v${YQ_VERSION}

tail +2 $MANIFESTS/apt.tsv > /tmp/xx
while IFS='	' read -a line; do
  pkg="${line[0]}"
  ver="${line[1]}"
  if [[ "${ver}" == "latest" ]]
  then
    pkgver="${pkg}"
  else
    pkgver="${pkg}=${ver}"
  fi
  dst="$APTS/uris/${pkg}.tsv"
  {
    echo "uri deb size signature"
    geturis "${pkgver}" || true
  } | awk -v OFS='\t' '{print $1,$2,$3,$4}' | tr -d "'" > $dst
  # remove .tsv file if empty
  # get line length of dst (format ::= <number> ' ' <filename>)
  a=($(wc -l $dst))
  # remove if empty (only header line present)
  ((1==a[0])) && rm -f $dst
done < /tmp/xx

echo "apts are primed"

# pypi priming
apt-get -yqq install --no-install-recommends \
  curl jq vim python3-pip python3-venv python3-poetry
cd; mkdir -p venv; cd venv
poetry init --python=">=3.13,<4.0" --no-interaction -vvv
poetry add pipgrip
eval $(poetry env activate)
tail +2 $MANIFESTS/pypi.tsv > /tmp/xx
while IFS='	' read -a line; do
  pkg="${line[0]}"
  ver="${line[1]}"
  if [[ "${ver}" == "latest" ]]
  then
    pkgver="${pkg}"
  else
    pkgver="${pkg}==${ver}"
  fi
  dst="$PYPIS/json/${pkg}.tsv"
  {
    echo "package==version"
    pipgrip "${pkgver}" || true
  } | awk -F "==" -v OFS='\t' '{print $1,$2}' > $dst
  # remove .tsv file if empty
  # get line length of dst (format ::= <number> ' ' <filename>)
  a=($(wc -l $dst))
  # remove if empty (only header line present)
  ((1==a[0])) && rm -f $dst
done < /tmp/xx

echo "pypis are primed"

dst=$RAWS/raw.tsv
tail +2 $MANIFESTS/raw.tsv > /tmp/xx
{
  echo "package version uri"
  while IFS='	' read -a line; do
    pkg="${line[0]}"
    ver="${line[1]}"
    uri="${line[2]}"
    if curl --output /dev/null --silent --location --head --fail "$uri"
    then
     echo "${line[@]}"
    else
      >&2 echo "uri $uri not found"
    fi || true
  done < /tmp/xx
} | awk -v OFS='\t' '{print $1,$2,$3}' > $dst

echo "raws are primed"
