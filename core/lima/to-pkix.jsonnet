// replace certinfo name fields with pkix name fields, and replace some values
local
  lib = import "to-pkix.libsonnet",
  subj = import "subj.libsonnet",
  mods = import "mods.libsonnet";

lib.to_pkix(subj) + lib.to_pkix(mods)
