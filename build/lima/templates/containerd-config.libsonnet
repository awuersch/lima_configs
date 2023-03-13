{
  "version": 2,
  "plugins": {
    "io.containerd.grpc.v1.cri": {
      "restrict_oom_score_adj": false,
      "sandbox_image": "registry.k8s.io/pause:3.7",
      "tolerate_missing_hugepages_controller": true,
      "containerd": {
        "default_runtime_name": "runc",
        "discard_unpacked_layers": true,
        "snapshotter": "overlayfs",
        "runtimes": {
          "runc": {
            "base_runtime_spec": "/etc/containerd/cri-base.json",
            "runtime_type": "io.containerd.runc.v2",
            "options": {
              "SystemdCgroup": true
            }
          },
          "test-handler": {
            "base_runtime_spec": "/etc/containerd/cri-base.json",
            "runtime_type": "io.containerd.runc.v2",
            "options": {
              "SystemdCgroup": true
            }
          }
        }
      },
      "registry": {
        "config_path": "/etc/containerd/certs.d"
      }
    }
  },
  "proxy_plugins": {
    "fuse-overlayfs": {
      "address": "/run/containerd-fuse-overlayfs.sock",
      "type": "snapshot"
    }
  }
}