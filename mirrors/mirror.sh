#!/usr/bin/env bash
set -euf -o pipefail

. /tmp/shared.sh

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
  gpg --quiet --no-tty --batch --gen-key apt-pgp-key.batch > /dev/null 2>&1
  gpg --quiet --armor --export apt > pgp-key.public
  gpg --quiet --armor --export-secret-keys apt > pgp-key.private
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
Suite: $APTSOURCE
Codename: $APTSOURCE
Version: 1.0
Architectures: ${arch}
Components: main
Description: A local apt repository
Date: $(date -Ru)
EOF
  do_hash "MD5Sum" "md5sum"
  do_hash "SHA1" "sha1sum"
  do_hash "SHA256" "sha256sum"
}

function create_mirror_apt_repo { #
  cd ${APTMIRROR}
  for d in pgp pool/main dists/${APTSOURCE}/main/binary-${arch}; do
    mkdir -p $d
  done
  generate_pgp_key ${PGPDIR}
  cat ${PGPDIR}/pgp-key.private | gpg --quiet --import
  # cleanup security
  rm -f ${PGPDIR}/pgp-key.private
  cd ${APTMIRROR}
  # allow glob
  set +f
  ln -s ${APTPKGS}/*.deb pool/main
  # forbid glob again
  set -f
  # assert: pwd is ${APTMIRROR} ...
  for s in dists/${APTSOURCE}; do
    for d in $s/main/binary-${arch}; do
      dpkg-scanpackages --arch ${arch} pool/ > $d/Packages 2>/dev/null
      cat $d/Packages | gzip -9 > $d/Packages.gz
    done
    cd $s
    {
      generate_apt_release > Release
      cat Release | gpg --default-key apt -abs > Release.gpg
      cat Release | gpg --default-key apt -abs --clearsign > InRelease
    } 2> /dev/null
  done
}

function wait_for_localhost_connection { # timeout port
  local seconds=$1
  local port=$2

  if timeout $seconds sh -c 'until nc -z $0 $1; do sleep 1; done' \
    $localhost $port 2>/dev/null
  then
    log_ecs info "connection to port $port succeeded"
  else
    log_ecs error "connection to port $port failed, exit status $?"
  fi
}

# main

# copy debs from $APTPKGS and install
copy_to_cache_and_install "${installedapts[@]}"

# we activate here so "python -m http.server" can work ...
poetry config virtualenvs.in-project true
cd ${VENV}
eval $(poetry env activate)

#
# apt
create_mirror_apt_repo
log_ecs info "apt mirror is created at ${APTMIRROR}"

cd ${MIRRORS}
port=$aptport
nohup python -m http.server --bind $localhost $port > ${APTLOG} 2>&1 &
wait_for_localhost_connection 5 $aptport

# make mirror the first choice for apt loading
mv /etc/apt/sources.list /etc/apt/sources.list.d/kali-rolling.list
echo "deb [arch=${arch} signed-by=${PGPDIR}/pgp-key.public] ${APTURL} ${APTSOURCE} main" > /etc/apt/sources.list

apt-get -qq update

log_ecs info "apt mirror is up."

#
# pypi
cd ${PYPIMIRROR}
pypi-mirror create -d $PYPIPKGS -m simple
log_ecs info "pypi mirror is created at ${PYPIMIRROR}"
nohup python -m http.server --bind $localhost $pypiport > ${PYPILOG} 2>&1 &
# wait until the port is listening
wait_for_localhost_connection 5 $pypiport
cd ${VENV}
poetry source add --priority=primary ${PYPISOURCE} ${PYPIURL}
poetry source add --priority=supplemental pypi https://pypi.org/simple
poetry lock

log_ecs info "pypi mirror is up."
