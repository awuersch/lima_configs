local
  args = import "args.libsonnet";

{
  "version": "0.1",
  "proxy": {
    "remoteurl": "https://" + args.domain
  },
  "log": {
    "fields": {
      "service": "registry"
    }
  },
  "storage": {
    "cache": {
      "blobdescriptor": "inmemory"
    },
    "filesystem": {
      "rootdirectory": "/var/lib/registry"
    }
  },
  "http": {
    "addr": ":" + args.port,
    "headers": {
      "X-Content-Type-Options": [
        "nosniff"
      ]
    }
  },
  "health": {
    "storagedriver": {
      "enabled": true,
      "interval": "10s",
      "threshold": 3
    }
  }
}
