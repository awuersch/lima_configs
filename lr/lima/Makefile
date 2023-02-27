# Makefile

all: basic.yaml lr0.yaml lr1.yaml lr0-kind-1-cilium.yaml

clean:
	rm -f *.yaml templates/args.libsonnet

basic.yaml:
	jsonnet templates/basic.jsonnet | yq -P > $@

lr0.yaml:
	echo '{ vm_name: "lr", vm_index: 0, workdir: "lr" }' > templates/args.libsonnet
	jsonnet templates/lr.jsonnet | yq -P > $@

lr1.yaml:
	echo '{ vm_name: "lr", vm_index: 1, workdir: "lr" }' > templates/args.libsonnet
	jsonnet templates/lr.jsonnet | yq -P > $@

kind-1-cilium.yaml:
	echo '{ name: "1-cilium", nibble: 1 }' > templates/args.libsonnet
	jsonnet templates/kind-cluster.jsonnet | yq -P > $@

.PHONY: clean
