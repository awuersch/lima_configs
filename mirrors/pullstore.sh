#! /usr/bin/env bash
set -euf

# common defines used by prime and pullstore
. /tmp/shared.sh

function copy_to_cache_and_install { # apts
  local apt apts="$@"
  cd $APTPKGS
  for apt in $apts; do
    # copy deb files to default apt cache
    cp $(tail +2 $APTS/uris/${apt}.tsv | cut -d '	' -f2) $APTCACHE
  done
  apt-get -yqq install --no-install-recommends $apts
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

# copy debs from $APTPKGS and install
copy_to_cache_and_install $aptapts

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

# need to unquote version string to get colons, etc
function unquote_version { # version
  local code="import urllib.parse; print(urllib.parse.unquote('$1'))"
  echo "$(python3 -c "${code}")"
}

trap 'rm -f /tmp/xx' EXIT ERR

skip_apts=true
if [[ X"${skip_apts}" != X"true" ]]; then
  # read primed apts
  # allow glob, and replace empty globs with an empty string
  set +f; shopt -s nullglob
  for f in $APTS/uris/*.tsv; do
    # get basename of f and strip off suffix
    pkg=$(basename $f .tsv)
    >&2 echo "seeking $pkg in $f"
    tail +2 $f > /tmp/xx
    while IFS='	' read -a line; do
      url="${line[0]}"
      deb="${line[1]}"
      size="${line[2]}"
      signature="${line[3]}"
      debpkg=${deb%%_*}
      >&2 echo "looking at $debpkg"
      if [[ X"$debpkg" == X"$pkg" ]]; then
        >&2 echo "$pkg in $debpkg"
        x=${deb#*_}
        version="$(unquote_version ${x%%_*})"
        if [[ -f $APTPKGS/$deb ]]; then
          >&2 echo "$pkg $version is already in $APTPKGS"
        else
          >&2 echo "pulling $pkg $version"
          apt-get -yqq install --download-only --no-install-recommends \
            "${pkg}=${version}"
          >&2 echo "pulled $pkg $version"
          debs=($APTCACHE/*.deb)
          if (( ${#debs[@]} > 0 )); then
            # TODO: check size and signature of deb file here!
            mv $APTCACHE/*.deb $APTPKGS
            >&2 echo "stored $pkg $version and dependencies in $APTPKGS"
          else
            >&2 echo "no deb files were found for $pkg $version !!"
          fi
          break
        fi
      else
        >&2 echo "$pkg not in $debpkg"
      fi
    done < /tmp/xx
  done
  # forbid glob again
  shopt -u nullglob; set -f

  echo "apts are pulled and stored"
fi

# copy pypi debs from $APTPKGS and install
copy_to_cache_and_install $pypiapts

# set up venv and mirror for pulling python libraries
VENV=/opt/venv
mkdir -p $VENV
cd $VENV
poetry init --python=">=3.13,<4.0" --no-interaction -vvv
poetry add python-pypi-mirror
eval $(poetry env activate)
# allow glob
set +f
shopt -s nullglob
for f in $PYPIS/json/*.tsv; do
  # get basename of f and strip off suffix
  pkg=$(basename $f .tsv)
  tail +2 $f > /tmp/xx
  while IFS='	' read -a line; do
    package="${line[0]}"
    version="${line[1]}"
    >&2 echo "looking at $package"
    if [[ X"$package" == X"$pkg" ]]; then
      >&2 echo "$pkg in $package"
      pypi-mirror download -d $PYPIPKGS ${package}==${version}
      >&2 echo "pulled $package $version"
    fi
  done < /tmp/xx
done
# forbid glob again
shopt -u nullglob
set -f

echo "pypis are pulled and stored"

# curl raw URLs
cd $RAWPKGS
tail +2 $RAWS/raw.tsv > /tmp/xx
while IFS='	' read -a line; do
  pkg="${line[0]}"
  ver="${line[1]}"
  uri="${line[2]}"
  curl --silent --fail -LO "$uri" || true
done < /tmp/xx

echo "raws are pulled and stored"
