local svcs = import 'svcs.libsonnet',
      targetPorts(arr, name) = [p.targetPort for p in arr if p.name == name],
      namedPorts = [
        { name: item.metadata.name, targetPort: item.spec.ports[0].targetPort }
        for item in svcs.items
        if
            targetPorts(item.spec.ports, "http-web") != []
          &&
            std.endsWith(item.metadata.name, "operated") == false
      ];

std.join(
  "\n",
  [std.join("\t", [o.name, o.targetPort + ""]) for o in namedPorts]
)
