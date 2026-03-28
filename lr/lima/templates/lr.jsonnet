// vz json for vz.yaml

local
  args = import 'args.libsonnet',
  files = import 'files.libsonnet',
  strings = files[args.vm_name],
  locations = import 'locations.libsonnet',
  resources = import 'resources.libsonnet',
  params = import 'params.libsonnet',
  vm_indexed_name = args.vm_name + std.toString(args.vm_index),
  datadir = params.macbookpro.misc.limaTop + "/" + vm_indexed_name,
  workdir = params.macbookpro.misc.limaTop + "/" + args.workdir,
  workspace = "/Users/" + args.user + "/workspace",
  host_workdir = workspace + "/vms/" + workdir,
  hosthome = host_workdir + "/home" + "/" + vm_indexed_name,
  host_volumes = workspace + "/volumes/",
  model = "macbookpro";

{
  images: locations.images[args.os][args.images_version],
  cpus: resources.macbookpro.cpus,
  memory: resources.macbookpro.memory,
  disk: resources.macbookpro.disk,
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
      location: workspace + "/opt/" + datadir,
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
