#!/bin/bash
set -eux -o pipefail
# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
command -v docker >/dev/null 2>&1 && exit 0
if [ ! -e /etc/systemd/system/docker.socket.d/override.conf ]; then
  mkdir -p /etc/systemd/system/docker.socket.d
  # Alternatively we could just add the user to the "docker" group, but that requires restarting the user session
  cat <<-EOF >/etc/systemd/system/docker.socket.d/override.conf
  [Socket]
  SocketUser=${LIMA_CIDATA_USER}
EOF
fi
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://get.docker.com | sh
apt-get install -y net-tools traceroute arping jq
