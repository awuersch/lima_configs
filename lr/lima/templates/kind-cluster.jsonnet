local
  args = import "args.libsonnet",
  cluster_name = args.name,
  service_subnet_nibble = args.nibble,
  pod_subnet_nibble = service_subnet_nibble + 10,
  build_node = function (role, n, zone) {
    "role": role,
    "labels": {
      "topology.kubernetes.io/zone": zone
    },
    "extraMounts": [
      {
        "hostPath": "/volumes/kind-" + role + n + "/ext4fs.img",
        "containerPath": "/var/csi/rawfile/ext4fs.img"
      }
    ]
  },
  nodes = [
    build_node("control-plane", "", "zone-a") {
      labels+: { "ingress-ready": true }
    },
    build_node("worker", "", "zone-a"),
    build_node("worker", "2", "zone-b"),
    build_node("worker", "3", "zone-c")
  ];

{
  "kind": "Cluster",
  "apiVersion": "kind.x-k8s.io/v1alpha4",
  "containerdConfigPatches": [
    "[plugins.\"io.containerd.grpc.v1.cri\".registry]\n  config_path = \"/etc/containerd/certs.d\""
  ],
  "name": args.name,
  "nodes": nodes,
  "networking": {
    "disableDefaultCNI": true,
    "kubeProxyMode": "none"
  }
}
