# build plugins toml for containerd registry patches

local 
  gen_port(index) = 5010 + (index * 10),
  domain_io(domain) = domain + ".io",

  plugin(kind, domain, rest) = {
    plugins: {
      "io.containerd.grpc.v1.cri": {
        registry: {
          [kind]: {
            [domain]: rest
          }
        }
      }
    }
  },

  configs_rest = {
    tls: { insecure_skip_verify: true }
  },
  mirrors_rest(domain, index) = {
    endpoint: ["http://registry-" + domain + ":" + gen_port(index)]
  },

  indexes(arr) = std.range(0, std.length(arr) - 1),

  registries = ["docker", "quay", "gcr", "k8s"],

  config_plugins = [
    plugin("configs", domain_io(registries[i]), configs_rest)
    for i in indexes(registries)
  ] + [plugin("configs", "us-docker.pkg.dev", configs_rest)],

  mirror_plugins = [
    plugin("mirrors", domain_io(registries[i]), mirrors_rest(domain_io(registries[i]), i))
    for i in indexes(registries)
  ] + [plugin("mirrors", "us-docker.pkg.dev", mirrors_rest("us-docker-pkg-dev", std.length(registries)))],

  indent = "  ",
  nl = "\n",

  indent_length = std.length(indent),

  depth_configs_dict = 5,
  depth_mirrors_dict = 4,

  config_tomls = [std.manifestTomlEx(d, indent) for d in config_plugins],
  mirror_tomls = [std.manifestTomlEx(d, indent) for d in mirror_plugins],

  filtered_lines(toml, depth) = std.filter(
    function (s) std.startsWith(s, std.repeat(indent, depth)),
    std.split(toml, nl)
  ),

  filtered_toml(toml, depth) =
    local offset = depth * indent_length;
    [
      std.substr(line, offset, std.length(line) - offset)
      for line in filtered_lines(toml, depth)
    ],
 
  # get indexes of lines starting with a string
  matching_indexes(arr, s) = [
    i
    for i in indexes(arr)
    if std.startsWith(arr[i], s)
  ],

  flag_ranges(i_arr, n) = std.set(
    std.flattenArrays(
      std.map(
        function (i) std.range(i, i+n),
        i_arr
      )
    )
  ),

  # join a range of lines
  join_lines(arr, indent) = indent + std.join("", [std.lstripChars(s, " ") for s in arr]),

  show_s(arr, i, n, matches, flags) =
    if std.member(matches, i)
    then
      join_lines(
        std.slice( arr, i, i+n, 1 ),
        indent
      )
    else if std.member(flags, i)
    then
      ''
    else arr[i],

  join_indexes(arr, s, n, indent) =
    local
      matches = matching_indexes(arr, s),
      flags = flag_ranges(matches, n-1);
    [
      show_s(arr, i, n, matches, flags)
      for i in indexes(arr)
      if show_s(arr, i, n, matches, flags) != ''
    ];
  
# flatten and filter lines from tomls
# std.join("\n",join_indexes(std.filter(function (s) std.length(s) != 0, std.split(s,nl)), "  endpoint", 3, indent))
std.join(
  "\n",
  join_indexes(
    std.split(
      std.lines(
        std.flattenArrays([
          [
            std.join(
              nl,
              filtered_toml(toml, depth_configs_dict)
            )
            for toml in config_tomls
          ],
          [
            std.join(
              nl,
              filtered_toml(toml, depth_mirrors_dict)
            )
            for toml in mirror_tomls
          ]
        ]),
      ),
      nl
    ),
    "  endpoint",
    3,
    indent
  )
)
