local
  config_plugins = import "containerd-config.libsonnet";

std.manifestTomlEx(config_plugins, std.repeat(" ", 2))
