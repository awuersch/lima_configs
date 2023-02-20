// parameters
local args = import 'args.libsonnet';

{
  macstudio: {
    ssh: {
      localPort: 60006 + args.vm_index
    },
    misc: {
      limaTop: "lima"
    }
  }
}
