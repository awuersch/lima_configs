#! /usr/bin/env bash
set -euf -o pipefail

MOUNTS=/mnt
MANIFESTS=$MOUNTS/manifests
STORAGE=$MOUNTS/storage

APTS=$STORAGE/apt

mkdir -p $APTS/uris

DEBIAN_FRONTEND=noninteractive
apt-get -yqq update
apt-get -yqq upgrade
# installs
apt-get -yqq --no-install-recommends install \
  curl apt-utils apt-rdepends vim
# data collection
for pkg in $(<$MANIFESTS/apt); do
  {
    echo "URI deb size signature"
    apt-get -yqq install --no-install-recommends --print-uris $pkg || true
  } | awk -v OFS='\t' '{print $1,$2,$3,$4}' | tr -d "'" > $APTS/uris/$pkg.tsv
done
# copy storage home
cp -r $APTS/uris /root

echo "alias urlfound='curl --output /dev/null --silent --head --fail'" >> $HOME/.bashrc
