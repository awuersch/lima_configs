#! /usr/bin/env bash
set -euf

# common defines used by prime and pullstore
. /tmp/shared.sh

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
apt-get -qq update
apt-get -qq upgrade

# need to unquote version string to get colons, etc
function unquote_version { # version
  local code="import urllib.parse; print(urllib.parse.unquote('$1'))"
  echo "$(python3 -c "${code}")"
}

trap 'rm -f /tmp/xx' EXIT ERR

# read primed apts
# allow glob, and replace empty globs with an empty string
set +f; shopt -s nullglob
for f in $APTS/uris/*.tsv; do
  # get basename of f and strip off suffix
  pkg=$(basename $f .tsv)
  echo "seeking $pkg in $f"
  tail +2 $f > /tmp/xx
  while IFS='	' read -a line; do
    url="${line[0]}"
    deb="${line[1]}"
    size="${line[2]}"
    signature="${line[3]}"
    debpkg=${deb%%_*}
    if [[ X"$debpkg" == X"$pkg" ]]; then
      x=${deb#*_}
      version="$(unquote_version ${x%%_*})"
      if [[ -f $APTPKGS/$deb ]]; then
        echo "$pkg $version is already in $APTPKGS"
      else
        echo "pulling $pkg $version"
        apt-get -qq install --download-only --no-install-recommends \
          "${pkg}=${version}"
        echo "pulled $pkg $version"
        debs=($APTCACHE/*.deb)
        if (( ${#debs[@]} > 0 )); then
          # TODO: check size and signature of deb file here!
          mv $APTCACHE/*.deb $APTPKGS
          echo "stored $pkg $version and dependencies in $APTPKGS"
        else
          echo "no deb files were found for $pkg $version !!"
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

# copy pypi debs from $APTPKGS and install
copy_to_cache_and_install $pypiapts

# set up venv and mirror for pulling python libraries
poetry config virtualenvs.in-project true
cd $VENV
eval $(poetry env activate)
# allow glob
set +f; shopt -s nullglob
for f in $PYPIS/json/*.tsv; do
  # get basename of f and strip off suffix
  pkg=$(basename $f .tsv)
  tail +2 $f > /tmp/xx
  while IFS='	' read -a line; do
    package="${line[0]}"
    version="${line[1]}"
    if [[ X"$package" == X"$pkg" ]]; then
      pypi-mirror download -d $PYPIPKGS ${package}==${version}
    fi
  done < /tmp/xx
done
# forbid glob again
shopt -u nullglob; set -f

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
