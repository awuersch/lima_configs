// vz json for vz.yaml

local
  args = import 'args.libsonnet',
  files = import 'files.libsonnet',
  strings = files[args.vm_name],
  resources = import 'resources.libsonnet',
  params = import 'params.libsonnet',
  vm_indexed_name = args.vm_name + std.toString(args.vm_index),
  datadir = params.macstudio.misc.limaTop + "/" + vm_indexed_name,
  workdir = params.macstudio.misc.limaTop + "/" + args.workdir,
  host_workdir = "/Users/tony/workspace/vms/" + workdir,
  hosthome = host_workdir + "/home" + "/" + vm_indexed_name;

{
  # Example to run ubuntu using vmType: vz instead of qemu (Default)
  # This example requires Lima v0.14.0 or later and macOS 13.
  # vmType: "vz": "Virtualization.framework" is a Apple framework that allows running Linux VMs on macOS 11. See https://developer.apple.com/documentation/virtualization
  # vmType: "qemu" (default): QEMU is a machine virtualizer that emulates a computer system. See https://www.qemu.org/

  vmType: "vz",
  rosetta: {
    enabled: true,
    binfmt: true
  },
  images: [
    {
      location: "https://cloud-images.ubuntu.com/releases/22.10/release-20230215/ubuntu-22.10-server-cloudimg-amd64.img",
      digest: "sha256:5e5c68cb12002111032d3239ade3763ce25639f1287a59d2509a1603c2b1f7e6",
      arch: "x86_64"
    },
    {
      location: "https://cloud-images.ubuntu.com/releases/22.10/release-20230215/ubuntu-22.10-server-cloudimg-arm64.img",
      digest: "sha256:76c350d3342d59f004040e1f66a5d7f64f8bc3465098afd0d7f83627b8b8523a",
      arch: "aarch64"
    },
    {
      # Fallback to the latest release image.
      # Hint: run `limactl prune` to invalidate the cache
      location: "https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-server-cloudimg-amd64.img",
      arch: "x86_64"
    },
    {
      # Fallback to the latest release image.
      # Hint: run `limactl prune` to invalidate the cache
      location: "https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-server-cloudimg-arm64.img",
      arch: "aarch64"
    }
  ],
  cpus: resources.macstudio.cpus,
  memory: resources.macstudio.memory,
  disk: resources.macstudio.disk,
  containerd: {
    system: false,
    user: false
  },
  mounts: [
    {
      location: host_workdir,
      mountPoint: "/workdir",
      writable: false
    },
    {
      location: "/tmp/" + datadir,
      mountPoint: "/tmp/lima",
      writable: true
    },
    {
      location: "/opt/" + datadir,
      mountPoint: "/opt/lima",
      writable: true
    }
  ],
  mountType: "virtiofs",
  provision: [
    {
      mode: "system",
      script: strings.scripts.provision
    }
  ],
  probes: [
    {
      script: strings.scripts.probes,
      hint: strings.hints.probes
    }
  ],
  portForwards: [
    {
      guestSocket: "/run/docker.sock",
      hostSocket: hosthome + "/docker.sock"
    }
  ],
  hostResolver: {
    hosts: {
      "host.docker.internal": "host.lima.internal"
    }
  },
  ssh: {
    localPort: 0,
    loadDotSSHPubKeys: false
  },
  networks: [
    {
      vzNAT: true
    }
  ]
}
