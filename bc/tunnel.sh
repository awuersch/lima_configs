#! /usr/bin/env bash
set -euf -o pipefail

# tip from Marga Manterola to Liz Rice
# read in https://medium.com/@lizrice/exposing-loadbalancer-services-running-on-kind-in-lima-vms-4d58cd4b5e12

# set up an SSH tunnel to a process

function errout {
  >&2 echo "usage: $0 port vm cluster svc namespace"
  exit 1
}

(($#==5)) || errout

p=$1; shift
vm=$1; shift
cluster=$1; shift
svc=$1; shift
ns=$1; shift

# set variables
export LIMA_HOME=${LIMA_HOME:-$HOME/.lima}
export KUBECONFIG=${LIMA_HOME}/$vm/.kube/config

# get path to private key
pk=${LIMA_HOME:-$HOME/.lima}/_config/user

# get vm ssh localPort
sshlp=$(limactl list --json $vm | jq -r .sshLocalPort)

# get service ip
svcip=$(kubectl --context $cluster get svc --output json --namespace $ns $svc | jq -r '.status.loadBalancer.ingress[0].ip')

# get service port
svcp=$(kubectl --context $cluster get svc --output json --namespace $ns $svc | jq -r '.spec.ports[0].port')

# put ssh to port in background
ssh -fN -i $pk -L $p:$svcip:$svcp -o Hostname=127.0.0.1 -o Port=$sshlp lima-$vm

echo "curl to port $svcp of localhost:$p"
