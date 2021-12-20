package = "skywalking-nginx-lua"
version = "0.6.0-0"
source = {
   url = "git://github.com/apache/skywalking-nginx-lua",
   branch = "v0.6.0",
}

description = {
   summary = "The Nginx Lua agent for Apache SkyWalking",
   homepage = "https://github.com/apache/skywalking-nginx-lua",
   license = "Apache License 2.0"
}

dependencies = {
   "lua-resty-http >= 0.15",
   "lua-resty-jit-uuid >= 0.0.7"
}

build = {
   type = "builtin",
   modules = {
      ["skywalking.client"] = "lib/skywalking/client.lua",
      ["skywalking.constants"] = "lib/skywalking/constants.lua",
      ["skywalking.correlation_context"] = "lib/skywalking/correlation_context.lua",
      ["skywalking.management"] = "lib/skywalking/management.lua",
      ["skywalking.segment_ref"] = "lib/skywalking/segment_ref.lua",
      ["skywalking.segment"] = "lib/skywalking/segment.lua",
      ["skywalking.span_layer"] = "lib/skywalking/span_layer.lua",
      ["skywalking.span"] = "lib/skywalking/span.lua",
      ["skywalking.tracer"] = "lib/skywalking/tracer.lua",
      ["skywalking.tracing_context"] = "lib/skywalking/tracing_context.lua",
      ["skywalking.util"] = "lib/skywalking/util.lua",
   }
}
