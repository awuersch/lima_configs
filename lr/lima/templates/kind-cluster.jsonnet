local
  args = import "args.libsonnet",
  kubeadm_patch = import "kubeadm-patches.libsonnet",
  containerd_patches = import "containerd-patches.libsonnet",
  cluster_name = args.name,
  service_subnet_nibble = args.nibble,
  pod_subnet_nibble = service_subnet_nibble + 10;

{
  "kind": "Cluster",
  "apiVersion": "kind.x-k8s.io/v1alpha4",
  "name": args.name,
  "nodes": [
    {
      "role": "control-plane",
      "labels": {
         "ingress-ready": true,
         "topology.kubernetes.io/zone": "zone-a"
      }
    },
    {
      "role": "control-plane",
      "labels": {
         "topology.kubernetes.io/zone": "zone-b"
      }
    },
    {
      "role": "control-plane",
      "labels": {
         "topology.kubernetes.io/zone": "zone-c"
      }
    },
    {
      "role": "worker",
      "labels": {
         "topology.kubernetes.io/zone": "zone-a"
      }
    },
    {
      "role": "worker",
      "labels": {
         "topology.kubernetes.io/zone": "zone-b"
      }
    },
    {
      "role": "worker",
      "labels": {
         "topology.kubernetes.io/zone": "zone-c"
      }
    }
  ],
  "networking": {
    "disableDefaultCNI": true,
    "kubeProxyMode": "none",
    "podSubnet": "10." + pod_subnet_nibble + ".0.0/16",
    "serviceSubnet": "10." + service_subnet_nibble + ".0.0/16"
  },
  # "kubeadmConfigPatches": [
  #   kubeadm_patch
  # ],
  "containerdConfigPatches": [
    containerd_patches
  ]
}

