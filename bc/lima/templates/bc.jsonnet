// vz json for vz.yaml

local
  args = import 'args.libsonnet',
  files = import 'files.libsonnet',
  strings = files[args.vm_name],
  resources = import 'resources.libsonnet',
  params = import 'params.libsonnet',
  datadir = params.macstudio.misc.limaTop + "/" + args.vm_name,
  workdir = params.macstudio.misc.limaTop + "/" + args.workdir,
  host_workdir = "/Users/tony/workspace/vms/" + workdir,
  hosthome = host_workdir + "/home" + "/" + args.vm_name;

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
      location: "https://cloud-images.ubuntu.com/releases/22.10/release-20221022/ubuntu-22.10-server-cloudimg-amd64.img",
      arch: "x86_64",
      digest: "sha256:8dc6cbae004d61dcd6098a93eeddebc3ddc7221df6688d1cbbbf0d86909aecf4"
    },
    {
      location: "https://cloud-images.ubuntu.com/releases/22.10/release-20221022/ubuntu-22.10-server-cloudimg-arm64.img",
      arch: "aarch64",
      digest: "sha256:9a95b52bc68639f3c60109d25d99fe0b3127d21632da437f00cb18e32bc528c4"
    },
    {
      # Fallback to the latest release image.
      # Hint: run `limactl prune` to invalidate the cache
      location: "https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-server-cloudimg-amd64.img",
      arch: "x86_64"
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
      writable: true
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
    localPort: params.macstudio.ssh.localPort,
    loadDotSSHPubKeys: true
  },
  networks: [
    {
      vzNAT: true
    }
  ]
}
