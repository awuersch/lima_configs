local
  args = import "args.libsonnet",
  cluster_name = args.name,
  service_subnet_nibble = args.nibble,
  pod_subnet_nibble = service_subnet_nibble + 10,
  build_node = function (role, zone) {
    "role": role,
    "labels": {
      "topology.kubernetes.io/zone": zone
    }
  },
  nodes = [
    build_node("control-plane", "zone-a") {
      labels+: { "ingress-ready": true }
    },
    build_node("control-plane", "zone-b"),
    build_node("control-plane", "zone-c"),
    build_node("worker", "zone-a"),
    build_node("worker", "zone-b"),
    build_node("worker", "zone-c")
  ],
  extra_mounts = {
    "extraMounts": [
      {
        "hostPath": "/workdir/containerd",
        "containerPath": "/etc/containerd",
        "readOnly": true
      }
    ]
  };

{
  "kind": "Cluster",
  "apiVersion": "kind.x-k8s.io/v1alpha4",
  "name": args.name,
  "nodes": [
    node + extra_mounts
    for node in nodes
  ],
  "networking": {
    "disableDefaultCNI": true,
    "kubeProxyMode": "none",
    "podSubnet": "10." + pod_subnet_nibble + ".0.0/16",
    "serviceSubnet": "10." + service_subnet_nibble + ".0.0/16"
  }
}
