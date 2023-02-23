local args = import 'args.libsonnet';

{
  [args.vm_name]: {
    scripts: {
      provision: importstr 'files/provision.sh',
      probes: importstr 'files/probes.sh'
    },
    hints: {
      probes: importstr 'files/probes.hint'
    }
  }
}
