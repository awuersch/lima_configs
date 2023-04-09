# Makefile

all: basic.yaml core0.yaml core1.yaml core0-kind-1-cilium.yaml

clean:
	rm -f *.yaml templates/args.libsonnet

basic.yaml:
	jsonnet templates/basic.jsonnet | yq -P > $@

core0.yaml:
	echo '{ vm_name: "core", vm_index: 0, workdir: "core" }' > templates/args.libsonnet
	jsonnet templates/core.jsonnet | yq -P > $@

core1.yaml:
	echo '{ vm_name: "core", vm_index: 1, workdir: "core" }' > templates/args.libsonnet
	jsonnet templates/core.jsonnet | yq -P > $@

build0.yaml:
	echo '{ vm_name: "build", vm_index: 0, workdir: "build" }' > templates/args.libsonnet
	jsonnet templates/core.jsonnet | yq -P > $@

kind-1-cilium.yaml:
	echo '{ name: "1-cilium", nibble: 1 }' > templates/args.libsonnet
	jsonnet templates/kind-cluster.jsonnet | yq -P > $@

kind-2-cilium.yaml:
	echo '{ name: "2-cilium", nibble: 2 }' > templates/args.libsonnet
	jsonnet templates/kind-cluster.jsonnet | yq -P > $@

config.toml:
	jsonnet -S templates/containerd-config.jsonnet > $@

.PHONY: clean
