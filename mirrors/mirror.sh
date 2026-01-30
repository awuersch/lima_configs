#!/usr/bin/env bash
set -euf -o pipefail

STORAGE=/mnt/archives
PACKAGES=$STORAGE/packages
ARCHIVES=$PACKAGES/apt
LOCALREPOS=/local-repos
APTREPO=$LOCALREPO/apt-repo
APTREPO=$APTREPO/log
PYPIREPO=/pypi
PYPILOG=$PYPIREPO/log
PGPDIR=$APTREPO/pgp
APTSOURCES=/etc/apt/sources.list.d
VENV=/opt/venv
PYPISOURCE=pypi-mirror
APTSOURCE=kali-mirror
GEMSOURCE=gemirror
arch=amd64
localhost=127.0.0.1
aptport=8000
pypiport=8001
gemport=2000
APTURL=http://$localhost:$aptport/apt-repo
PYPIURL=http://$localhost:$pypiport/simple

# dirs
rootdir=/root
localdir=/usr/local

# other
arch=amd64

# cf:
# https://github.com/earthly/example-apt-repo/blob/main/Earthfile

function generate_pgp_key { # tmpdir
  DIR=$1
  cd $DIR
  cat > apt-pgp-key.batch <<'EOF'
%echo Generating a local apt PGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: apt
Name-Email: noreply@us.af.mil.
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit"
EOF
  gpg --no-tty --batch --gen-key apt-pgp-key.batch
  gpg --armor --export apt > pgp-key.public
  gpg --armor --export-secret-keys apt > pgp-key.private
  # cleanup security
  rm -f apt-pgp-key.batch
}

function do_hash { # name cmd
  HASH_NAME=$1
  HASH_CMD=$2
  echo "${HASH_NAME}:"
  for f in $(find -type f); do
    f=$(echo $f | cut -c3-) # remove ./ prefix
    if [ "$f" = "Release" ]; then
      continue
    fi
    echo " $(${HASH_CMD} ${f} | cut -d" " -f1) $(wc -c $f)"
  done
}


function generate_apt_release { #
  cat << EOF
Origin: Mirror Apt Repository
Label: Apt
Suite: kali-mirror
Codename: kali-mirror
Version: 1.0
Architectures: ${arch}
Components: main
Description: A local apt repository
Date: ${\(date -Ru)
EOF
  do_hash "MD5Sum" "md5sum"
  do_hash "SHA1" "sha1sum"
  do_hash "SHA256" "sha256sum"
}

function create_mirror_apt_repo { #
  mkdir -p ${APTREPO}
  cd ${APTREPO}
  for d in pgp pool/main dists/${APTSOURCE}/main/binary-${arch}; do
    mkdir -p $d
  done
  generate_pgp_key ${PGPDIR}
  cat ${PGPDIR}/pgp-key.private | gpg --import
  # cleanup security
  rm -f ${PGPDIR}/pgp-key.private
  cd ${APTREPO}
  # allow glob
  set +f
  ln -s ${ARCHIVES}/*.deb pool/main
  # forbid glob again
  set -f
  # assert: pwd is ${APTREPO} ...
  for s in dists/${APTSOURCE}; do
    for d in $s/main/binary-${arch}; do
      dpkg-scanpackages --arch ${arch} pool/ > $d/Packages
      cat $d/Packages | gzip -9 > $d/Packages.gz
    done
    cd $s
    generate_apt_release > Release
    cat Release | gpg --default-key apt -abs > Release.gpg
    cat Release | gpg --default-key apt -abs --clearsign > InRelease
  done
}

# main

create_mirror_apt_repo
# make the mirror the first choice for apt loading
mv /etc/apt/sources.list /etc/apt/sources.list.d/kali-rolling.list
echo "deb [arch=${arch} signed-by=${PGPDIR}/pgp-key.public] ${APTURL} ${APTSOURCE} main" > /etc/apt/sources.list
cd ${VENV}
eval $(poetry env activate)
cd ${LOCALREPOS}
#
# apt
python -m http.server --bind $localhost $aptport > ${APTLOG} 2>&1 &
# wait until the port is listening
timeout 5 sh -c 'until nc -z $0 $1; do sleep 1; done' \
  $localhost $aptport
apt-get -yqq update
#
# pypi
cd ${PYPIREPO}
python -m http.server --bind $localhost $pypiport > ${PYPILOG} 2>&1 &
# wait until the port is listening
timeout 5 sh -c 'until nc -z $0 $1; do sleep 1; done' \
  $localhost $pypiport
cd ${VENV}
poetry source add --priority=explicit ${PYPISOURCE} ${PYPIURL}
# main loop
if [[ $# -eq 0 ]]; then
  while true; do sleep 100; done
else
  exec "$@"
fi

# apt pullstore test
apt-get -yqq install --download-only --no-install-recommends \
  wget tmux gron sudo
# apt install for pypi for pullstore
apt-get -yqq install --no-install-recommends python3-pip python3-poetry
# pypi mirror
mkdir -p $VENV
cd $VENV
poetry init --python=">=3.13,<4.0" --no-interaction -vvv
poetry add python-pypi-mirror
eval ${poetry env activate}
pypi-mirror download -d downloads \
  requests GitPython bc-python-hcl2 giturlparse python-gitlab \
  xmltodict elasticsearch8 boto3
