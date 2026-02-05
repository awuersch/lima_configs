#! /usr/bin/env bash
set -euf -o pipefail

function usage { # containername
  >&2 echo "usage: $0 containername"
  exit 1
}

(($#==0)) && usage
NAME=$1; shift

HOSTHOME=/Users/tony
CLONES=workspace/src/git/github.com
REPO=awuersch/lima_configs
MIRRORS=$HOSTHOME/$CLONES/$REPO/mirrors
STORAGE=/mnt/archive
PLATFORM=arm64

# pull image
IMG="kalilinux/kali-rolling"
>&2 echo "pulling image $IMG for platform $PLATFORM"
nerdctl pull --platform $PLATFORM "$IMG"

# run image
# bind manifests and storage to container
nerdctl run -d \
  --name $NAME \
  --platform $PLATFORM \
  --mount type=bind,source=$MIRRORS/manifests,target=/mnt/manifests,readonly \
  --mount type=bind,source=$STORAGE,target=$STORAGE \
  $IMG \
  bash -c \
  'while true; do sleep 100; done'

# wait for status running
SECONDS=100
((i=$SECONDS))
while ((i>0)); do
  status=$(nerdctl inspect $NAME | jq -r '.[].State.Status')
  [[ X"$status" == X"running" ]] && break || true
  ((i=i-1))
  >&2 echo "$i seconds remaining"
  sleep 1
done
((i==0)) && {
  >&2 echo "not running"
  exit 1
}
nerdctl cp $MIRRORS/$NAME.sh $NAME:/tmp/entrypoint.sh
for file in apt-rdepends.sh shared.sh; do
  nerdctl cp $MIRRORS/$file $NAME:/tmp/$file
done

# run entrypoint
nerdctl exec $NAME -- bash -c 'bash /tmp/entrypoint.sh'
