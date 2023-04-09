#!/usr/bin/env bash
set -euf -o pipefail

# generate certificates

TMPDIR=$(mktemp -d)
JSONDIR=~/workspace/vms/lima/core/lima/ca

# root ca
cd $TMPDIR
cfssl gencert -initca $JSONDIR/root-csr.json | cfssljson -bare ca
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem --config $JSONDIR/intermediate/config.json -profile intermediate_ca $JSONDIR/k8s-sub-csr.json | cfssljson -bare intermediate_ca

# cfssl gencert -initca  $JSONDIR/k8s-sub-csr.json | cfssljson -bare intermediate_ca
# cfssl sign -ca=ca.pem -ca-key=ca-key.pem --config $JSONDIR/intermediate/config.json -profile intermediate_ca intermediate_ca.csr | cfssljson -bare intermediate_ca
