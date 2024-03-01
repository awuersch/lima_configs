#! /usr/bin/env bash
set -euf -o pipefail

# uninstall all lima stuff
VM=lr0
CL=1-cilium

echo uninstall $CL
kind delete cluster -n $CL
echo uninstall $VM
limactl stop $VM
limactl delete $VM
echo remove $VM dirs
rm -rf ~/workspace/opt/lima/$VM /tmp/lima/$VM home/$VM
echo Done.
