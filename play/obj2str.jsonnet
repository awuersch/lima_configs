std.join(
  ",",
  std.objectValues(
    std.mapWithKey(
      function(k,v) k+"="+v,
      import "obj.libsonnet"
    )
  )
)
