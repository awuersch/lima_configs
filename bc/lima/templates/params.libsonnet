// parameters
local args = import 'args.libsonnet';

{
  macstudio: {
    ssh: {
      localPort: 60006 + std.parseInt(std.strReplace(args.vm_name, 'bc', ''))
    },
    misc: {
      limaTop: "lima"
    }
  }
}
