// basic json for basic.yaml

{
  vmType: "vz",
  rosetta: {
    enabled: true,
    binfmt: true
  },
  images: [
    {
      location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img",
      arch: "x86_64"
    },
    {
      location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img",
      arch: "aarch64"
    }
  ],
  mounts: [
    {
      location: "~"
    },
    {
      location: "/tmp/lima",
      writable: true
    }
  ],
  mountType: "virtiofs",
  networks: [
    {
      vzNAT: true
    }
  ]
}
