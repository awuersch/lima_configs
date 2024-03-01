#! /usr/bin/env bash
set -euf -o pipefail

# install all lima stuff
VM=lr0
CL=1-cilium

echo create dirs
mkdir -p /tmp/lima
echo make
(cd lima; make clean; make)
echo install
bash -x ./install.sh $VM 2>&1 | tee install-${VM}.out
echo install-kind
bash -x ./install-kind.sh $VM $CL 2>&1 | tee install-kind-${VM}-${CL}.out
echo install-kube-prometheus-stack
bash -x ./install-kube-prometheus-stack.sh $VM $CL 2>&1 | tee install-kube-prom-stack-${VM}-${CL}.out
echo limit-local-provisioner
bash -x ./limit-local-provisioner.sh $VM $CL 2>&1 | tee install-limit-provisioner-${VM}-${CL}.out
echo Done.
