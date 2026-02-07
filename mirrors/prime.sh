#! /usr/bin/env bash
set -euf

. /tmp/shared.sh

# the magic command for apt
function geturis { # pkgver
  local pkgver=$1
  apt-get -qq install --no-install-recommends --print-uris $pkgver
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

# main

# get dependencies and download to-be-installeds
log_ecs info "getting apt package dependencies"

for pkg in "${installedapts[@]}"; do
  dst="$APTS/uris/${pkg}.tsv"
  get_depends ${pkg} ${dst}
done

log_ecs info "apt dependencies are in $APTS/uris"

log_ecs info "downloading apt packages ${installedapts[@]}"
apt-get -qq install \
  --download-only --no-install-recommends \
  "${installedapts[@]}"

log_ecs info "${installedapts[@]} are downloaded."

# allow glob
set +f; shopt -s nullglob
mv $APTCACHE/*.deb $APTPKGS
# forbid glob again
shopt -u nullglob; set -f

log_ecs info "apt debs are in $APTPKGS"

# apt apt installing with no install messages

log_ecs info "installing apt packages $aptapts ..."
apt-get -qq install --no-install-recommends $aptapts < /dev/null > /dev/null

# note: can use log_ecs() from hereon in now that jq is installed

log_ecs info "$aptapts are installed."

# add apt repositories
#
hashicorpurl=https://apt.releases.hashicorp.com
hashicorpgpg=${keyringsdir}/hashicorp-archive-keyring.gpg
curl -fsSL ${hashicorpurl}/gpg | gpg --dearmor -o ${hashicorpgpg}
echo "deb [arch=${arch} signed-by=${hashicorpgpg}] ${hashicorpurl} bookworm main" > ${aptsources}/hashicorp.list
#
cloudfoundryurl=https://packages.cloudfoundry.org/debian
cloudfoundrykey=${cloudfoundryurl}/cli.cloudfoundry.org.key
cloudfoundrygpg=${keyringsdir}/cloudfoundry-keyring.gpg
curl -fsSL ${cloudfoundrykey} | gpg --dearmor -o ${cloudfoundrygpg}
echo "deb [arch=${arch} signed-by=${cloudfoundrygpg}] ${cloudfoundryurl} stable main" > ${aptsources}/cloudfoundry.list
#
TZ=UTC
echo $TZ > /etc/timezone

# update with new repositories
apt-get -qq update
apt-get -qq upgrade < /dev/null > /dev/null

log_ecs info "priming, i.e., getting apt dependencies from manifest."

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

log_ecs info "apts are primed"

# pypi apt installing with no install messages

log_ecs info "installing apt packages $pypiapts ..."
apt-get -qq install --no-install-recommends $pypiapts < /dev/null > /dev/null
log_ecs info "$pypiapts are installed."

log_ecs info "installing pypi packages $pypipypis ..."
poetry config virtualenvs.in-project true
cd $VENV
poetry init --python=">=3.13,<4.0" --no-interaction -vvv
poetry add $pypipypis --quiet --no-interaction
log_ecs info "python $pypipypis are installed."
eval $(poetry env activate)

log_ecs info "priming, i.e., getting pypi dependencies from manifest."

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

log_ecs info "pypis are primed"

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
     log_ecs error "uri $uri not found"
    fi || true
  done < /tmp/xx
} | awk -v OFS='\t' '{print $1,$2,$3}' > $dst

log_ecs info "raws are primed"
