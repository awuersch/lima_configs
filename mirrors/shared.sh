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
arch=arm64

# ipaddrs and URLs
localhost=127.0.0.1
aptport=8000
pypiport=8001
APTURL=http://$localhost:$aptport/apt
PYPIURL=http://$localhost:$pypiport/simple

LISTS=$STORAGE/lists
APTS=$LISTS/apt
PYPIS=$LISTS/pypi
RAWS=$LISTS/raw

PKGS=$STORAGE/pkgs
APTPKGS=$PKGS/apt
APTCACHE=/var/cache/apt/archives
PYPIPKGS=$PKGS/pypi
RAWPKGS=$PKGS/raw

VENV=$STORAGE/venv

MIRRORS=$STORAGE/mirrors
APTMIRROR=$MIRRORS/apt
PYPIMIRROR=$MIRRORS/pypi
APTLOG=$APTMIRROR/log
PYPILOG=$PYPIMIRROR/log
PGPDIR=$APTMIRROR/pgp
APTSOURCES=/etc/apt/sources.list.d
APTSOURCE=kali-mirror
PYPISOURCE=pypi-mirror

mkdir -p \
  $VENV \
  $APTS/uris \
  $PYPIS/json \
  $RAWS \
  $APTPKGS \
  $PYPIPKGS \
  $RAWPKGS \
  $APTMIRROR \
  $PYPIMIRROR \
  $PGPDIR

# these are minimals
aptapts="ca-certificates curl gnupg python3 jq"
# see python-slim 3.14 trixie for these, to aid python package builds
pypiapts="dpkg-dev gcc cython3 libbz2-dev libc6-dev libdb-dev libffi-dev libgdbm-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev libzstd-dev make tk-dev uuid-dev wget xz-utils zlib1g-dev libyaml-dev libcurl4t64 libcurl4-openssl-dev python3-dev python3-poetry"
mirrorapts="netcat-openbsd"
installedapts=($aptapts $pypiapts $mirrorapts)
pypipypis="pipgrip python-pypi-mirror"
otherapts="vim"

function copy_to_cache_and_install { # apts
  local apt apts="$@"
  cd $APTPKGS
  for apt in $apts; do
    # copy deb files to default apt cache
    cp $(tail +2 $APTS/uris/${apt}.tsv | cut -d '	' -f2) $APTCACHE
  done
  # install with no messages
  echo "installing apt packages $apts ..."
  apt-get -yqq install --no-install-recommends $apts < /dev/null > /dev/null
  echo "$apts are installed."
  # remove from cache
  # allow glob
  set +f
  if [[ X"$APTCACHE/*.deb" != X"$APTCACHE/*.deb" ]]; then
    # yes, there are .deb files there ...
    rm $APTCACHE/*.deb;
  fi
  # forbid glob again
  set -f
  cd -
}

export DEBIAN_FRONTEND=noninteractive

apt-get -yqq update
