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
APTCACHE=/var/cache/apt/archives
PYPIPKGS=$PKGS/pypi
RAWPKGS=$PKGS/raw

mkdir -p \
  $APTS/uris \
  $PYPIS/json \
  $RAWS \
  $APTPKGS \
  $PYPIPKGS \
  $RAWPKGS

# these are minimals
aptapts="ca-certificates curl gnupg python3 jq"
# see python-slim 3.14 trixie for these, to aid python package builds
pypiapts="dpkg-dev gcc cython3 libbz2-dev libc6-dev libdb-dev libffi-dev libgdbm-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev libzstd-dev make tk-dev uuid-dev wget xz-utils zlib1g-dev libyaml-dev libcurl4t64 libcurl4-openssl-dev python3-dev python3-poetry"
installedapts=($aptapts $pypiapts)
pypipypis="pipgrip pypi-mirror"
otherapts="vim"

export DEBIAN_FRONTEND=noninteractive

apt-get -yqq update
