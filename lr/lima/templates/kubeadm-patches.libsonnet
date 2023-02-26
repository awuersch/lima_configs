# generate string for kubeadm config patches

local
  labels = {
    "ingress-ready":"true",
    "topology.kubernetes.io/region":"us-east",
    "topology.kubernetes.io/zone":"us-east-b"
  },
  labels2str(labels) =
    std.join(
      ",",
      std.objectValues(
        std.mapWithKey(
          function(k,v) k+"="+v,
          labels
        )
      )
    ),
  config =
    {
      "kind": "InitConfiguration",
      "nodeRegistration": {
        "kubeletExtraArgs": {
          "node-labels": labels2str(labels)
        }
      }
    };

# std.manifestYamlDoc(value, indent_array_in_object=false, quote_keys=true)
std.manifestYamlDoc(config, quote_keys=false)
