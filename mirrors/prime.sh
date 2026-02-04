#! /usr/bin/env bash
set -euf

. /tmp/shared.sh

# the magic command for apt
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

# check if a manifest entry is already installed
function contains_element { # match arr
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# get dependencies and download to-be-installeds
for pkg in $aptapts $pypiapts; do
  dst="$APTS/uris/${pkg}.tsv"
  get_depends ${pkg} ${dst}
done

echo "apt dependencies are in $APTS/uris"

apt-get -yqq install --download-only --no-install-recommends $aptapts $pypiapts
# allow glob
set +f; shopt -s nullglob
mv $APTCACHE/*.deb $APTPKGS
# forbid glob again
shopt -u nullglob; set -f

echo "apt debs are in $APTPKGS"

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
    if $(contains_element ${pkg} ${installedapts[@]}); then
       # manifest line is already installed
       continue
    fi
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
