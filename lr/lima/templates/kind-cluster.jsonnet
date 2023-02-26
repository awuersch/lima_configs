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
      "extraPortMappings": [
        {
          "containerPort": 6443,
          "hostPort": 7001
        }
      ]
    }
  ],
  "networking": {
    "serviceSubnet": "10." + service_subnet_nibble + ".0.0/16",
    "podSubnet": "10." + pod_subnet_nibble + ".0.0/16"
  },
  "kubeadmConfigPatches": [
    kubeadm_patch
  ],
  "containerdConfigPatches": [
    containerd_patches
  ]
}

