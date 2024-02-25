// vz json for vz.yaml

local
  args = import 'args.libsonnet',
  files = import 'files.libsonnet',
  strings = files[args.vm_name],
  locations = import 'locations.libsonnet',
  resources = import 'resources.libsonnet',
  params = import 'params.libsonnet',
  vm_indexed_name = args.vm_name + std.toString(args.vm_index),
  datadir = params.macstudio.misc.limaTop + "/" + vm_indexed_name,
  workdir = params.macstudio.misc.limaTop + "/" + args.workdir,
  workspace = "/Users/tony/workspace/",
  host_workdir = workspace + "vms/" + workdir,
  hosthome = host_workdir + "/home" + "/" + vm_indexed_name,
  host_volumes = "/Users/tony/workspace/volumes/";

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
  images: locations.images[args.os][args.images_version],
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
      location: workspace + "opt/" + datadir,
      mountPoint: "/opt/lima",
      writable: true
    },
    {
      location: host_volumes,
      mountPoint: "/volumes",
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
