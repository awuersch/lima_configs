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
PLAY=$HOSTHOME/$CLONES/$REPO/play

# pull image
IMG="kalilinux/kali-rolling"
>&2 echo "pulling image $IMG"
nerdctl pull --platform amd64 "$IMG"

# run immage
nerdctl run -d \
  --platform amd64 \
  --name $NAME \
  --mount type=bind,source=$PLAY/manifests,target=/mnt/manifests,readonly \
  --mount type=tmpfs,target=/mnt/storage,rw \
  --platform amd64 \
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
nerdctl cp $PLAY/$NAME.sh $NAME:/tmp/entrypoint.sh
for file in apt-rdepends.sh; do
  nerdctl cp $PLAY/$file $NAME:/tmp/$file
done

# run entrypoint
nerdctl exec $NAME -- bash -c 'bash -x /tmp/entrypoint.sh'

# pick up apts
rm -rf $HOME/apts
nerdctl cp $NAME:root/uris $HOME
