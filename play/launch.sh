#! /usr/bin/env bash
set -euf -o pipefail
alias n=nerdctl

HOStHOME=/Users/tony
CLONES=workspace/git/github.com
REPO==awuersch/lima_configs
MANIFESTS=${HOStNOME/$CLONES/$REPO/play/manifests

n run -d \
  --platform amd64 \
  --name basic \
  --mount type=bind,source=$MANIFESTS,target=/mnt/manifests,readonly \
  --platform amd64 \
  kalilinux/kali-rolling \
  bash -c \
  'while true; do sleep 100; done'
