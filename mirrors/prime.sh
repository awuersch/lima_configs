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

echo "alias urlfound='curl --output /dev/null --silent --head --fail'" >> $HOME/.bashrc

# apt priming
MOUNTS=/mnt
MANIFESTS=$MOUNTS/manifests
STORAGE=/tmp/storage
mkdir -p $STORAGE

APTS=$STORAGE/apt
PYPIS=$STORAGE/pypi

mkdir -p $APTS/uris
mkdir -p $PYPIS/json

DEBIAN_FRONTEND=noninteractive
apt-get -yqq update
apt-get -yqq upgrade
# add apt repositories -- TBD
#   hashicorp
#   cloudfoundry
#
# ".tsv" files are per-line tab-separated values with a header line on top
# get package version metadata (avoiding header line by using tail +2)
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
# copy storage to VM home
cd; mkdir -p apt
cp -r $APTS/uris apt

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
# copy storage to VM home
cd; mkdir -p pypi
cp -r $PYPIS/json pypi
