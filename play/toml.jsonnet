local exs = [
{
  plugins: {
    "io.containerd.sssy.v1.cri": {
      registry: {
        mirrors: {
          "docker.io": {
            endpoint: ["http://registry-dockerio:5030"]
          }
        }
      }
    }
  }
},
{
  plugins: {
    "io.containerd.grpc.v1.cri": {
      registry: {
        mirrors: {
          "docker.io": {
            endpoint: ["http://registry-dockerio:5030"]
          }
        }
      }
    }
  }
}
];

std.lines([std.manifestTomlEx(ex, "  ") for ex in exs])
