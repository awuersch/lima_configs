# Makefile

all: basic.yaml bc0.yaml bc1.yaml

clean:
	rm -f *.yaml templates/args.libsonnet

basic.yaml:
	jsonnet templates/basic.jsonnet | yq -P > $@

bc0.yaml:
	echo '{ vm_name: "bc", vm_index: 0, workdir: "bc" }' > templates/args.libsonnet
	jsonnet templates/bc.jsonnet | yq -P > $@

bc1.yaml:
	echo '{ vm_name: "bc", vm_index: 1, workdir: "bc" }' > templates/args.libsonnet
	jsonnet templates/bc.jsonnet | yq -P > $@

.PHONY: clean
