#! /usr/bin/env bash
set -euf -o pipefail

# push to mirror registry

IMG="ingress-nginx/kube-webhook-certgen"
TAG="v20221220-controller-v1.5.1-58-g787ea74b"
SRC="registry.k8s.io/$IMG:$TAG"
DST="registry-k8sio:5050/$IMG:$TAG"

docker tag "$SRC" "$DST"
docker push "$DST"
