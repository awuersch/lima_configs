# Makefile

all: basic.yaml lr0.yaml lr1.yaml kind-1-cilium.yaml kind-2-cilium.yaml

clean:
	rm -f *.yaml templates/args.libsonnet

basic.yaml:
	jsonnet templates/basic.jsonnet | yq -y > $@

lr0.yaml:
	echo '{ user: "$USER", os: "ubuntu", images_version: "23.10", vm_name: "lr", vm_index: 0, workdir: "lr" }' > templates/args.libsonnet
	jsonnet templates/lr.jsonnet | yq -y > $@

lr1.yaml:
	echo '{ user: "$USER", os: "ubuntu", images_version: "23.10", vm_name: "lr", vm_index: 1, workdir: "lr" }' > templates/args.libsonnet
	jsonnet templates/lr.jsonnet | yq -y > $@

build0.yaml:
	echo '{ user: "$USER", os: "ubuntu", images_version: "23.10", vm_name: "build", vm_index: 0, workdir: "build" }' > templates/args.libsonnet
	jsonnet templates/lr.jsonnet | yq -y > $@

kind-1-cilium.yaml:
	echo '{ name: "1-cilium", nibble: 1 }' > templates/args.libsonnet
	jsonnet templates/kind-cluster.jsonnet | yq -y > $@

kind-2-cilium.yaml:
	echo '{ name: "2-cilium", nibble: 2 }' > templates/args.libsonnet
	jsonnet templates/kind-cluster.jsonnet | yq -y > $@

config.toml:
	jsonnet -S templates/containerd-config.jsonnet > $@

.PHONY: clean
