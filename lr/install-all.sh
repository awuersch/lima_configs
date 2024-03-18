#! /usr/bin/env bash
set -euf -o pipefail

# install all lima stuff
VM=lr0
CL=1-cilium

echo create dirs
mkdir -p /tmp/lima
echo make
(cd lima; make clean; make)
if [[ -d ~/workspae/volumes/kind-worker ]]; then
  DO_MKFS=true
else
  DO_MKFS=false
  echo creating /tmp/lima ~/workspace/opt/lima
  mkdir -p /tmp/lima ~/workspace/opt/lima
  echo building volumes
  bash -x ./setup-volumes.sh > setup-volumes.out 2>&1
echo install
bash -x ./install.sh $VM 2>&1 | tee install-${VM}.out
if [[ "${DO_MKFS}" == "true" ]]; then
  export LIMA_INSTANCE=lr0 CLUSTER=1-cilium
  . ./source-env.sh
  limactl shell --workdir /workdir --shell ./mkfs-volumes.sh lr0
fi
echo install-kind
bash -x ./install-kind.sh $VM $CL 2>&1 | tee install-kind-${VM}-${CL}.out
echo install-kube-prometheus-stack
bash -x ./install-kube-prometheus-stack.sh $VM $CL 2>&1 | tee install-kube-prom-stack-${VM}-${CL}.out
echo limit-local-provisioner
bash -x ./limit-local-provisioner.sh $VM $CL 2>&1 | tee install-limit-provisioner-${VM}-${CL}.out
echo install-loki
bash -x ./install-loki.sh $VM $CL 2>&1 | tee install-loki-${VM}-${CL}.out
echo install-argo-cd
bash -x ./install-argo-cd.sh $VM $CL 2>&1 | tee install-argo-cd-${VM}-${CL}.out
echo install-kyverno
bash -x ./install-kyverno.sh $VM $CL 2>&1 | tee install-kyverno-${VM}-${CL}.out
echo install-istio
# bash -x ./install-istio.sh $VM $CL 2>&1 | tee install-istio-${VM}-${CL}.out
echo install-istio POSTPONED
echo Done.
