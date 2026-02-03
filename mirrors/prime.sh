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


function get_depends { # pkgver dst
  local pkgver="$1"
  local dst="$2"
  {
    echo "uri deb size signature"
    geturis "${pkgver}" || true
  } | awk -v OFS='\t' '{print $1,$2,$3,$4}' | tr -d "'" > $dst
  # remove .tsv file if empty
  # get line length of dst (format ::= <number> ' ' <filename>)
  local a=($(wc -l $dst))
  # remove if empty (only header line present)
  ((1==a[0])) && rm -f $dst
  return 0
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

# other
arch=amd64

LISTS=$STORAGE/lists
APTS=$LISTS/apt
PYPIS=$LISTS/pypi
RAWS=$LISTS/raw

PKGS=$STORAGE/pkgs
APTPKGS=$PKGS/apt
INSTALLEDS=$APTPKGS/installed
APTCACHE=/var/cache/apt/archives
PYPIPKGS=$PKGS/pypi
RAWPKGS=$PKGS/raw

mkdir -p $APTS/uris
mkdir -p $PYPIS/json
mkdir -p $RAWS

aptapts="ca-certificates curl gnupg"
pypiapts="python3-poetry"
otherapts="jq vim"
maybeapts="python3-pip python3-venv"
pypipypis="pipgrip pypi-mirror"

export DEBIAN_FRONTEND=noninteractive

apt-get -yqq update

# get dependencies and download to-be-installeds
mkdir -p $INSTALLEDS
for pkg in $aptapts $pypiapts; do
  dst="$APTS/uris/${pkg}.tsv"
  get_depends ${pkg} ${dst}
  mkdir -p $INSTALLEDS/$pkg
  apt-get -yqq install --download-only --no-install-recommends $pkg
  # allow glob
  set +f
  mv $APTCACHE/*.deb $INSTALLEDS/$pkg
  # forbid glob again
  set -f
done

echo "apt downloads are copied to $INSTALLEDS"

apt-get -yqq install --no-install-recommends $aptapts

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
TZ=UTC
echo $TZ > /etc/timezone

# update with new repositories
apt-get -yqq update
apt-get -yqq upgrade

# ".tsv" files are per-line tab-separated values with a header line on top
# get package version metadata (avoiding header line by using tail +2)
trap 'rm -f /tmp/xx' EXIT ERR
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
  get_depends "${pkgver}" $dst
done < /tmp/xx

echo "apts are primed"

# pypi priming
apt-get -yqq install --no-install-recommends \
  $pypiapts
cd; mkdir -p venv; cd venv
poetry init --python=">=3.13,<4.0" --no-interaction -vvv
poetry add $pypipypis
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
