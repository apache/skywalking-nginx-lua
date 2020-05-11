package = "skywalking-nginx-lua"
version = "0.1-0"
source = {
   url = "git://github.com/apache/skywalking-nginx-lua",
   tag = "v0.1.0",
}

description = {
   summary = "The Nginx Lua agent for Apache SkyWalking",
   homepage = "https://github.com/apache/skywalking-nginx-lua",
   license = "Apache License 2.0"
}

dependencies = {
   "lua-resty-http = 0.15"
}

build = {
   type = "builtin",
   modules = {
    ["skywalking.register"] = "lib/skywalking/register.lua",
    ["skywalking.segment_ref"] = "lib/skywalking/segment_ref.lua",
    ["skywalking.segment"] = "lib/skywalking/segment.lua",
    ["skywalking.span_layer"] = "lib/skywalking/span_layer.lua",
    ["skywalking.span"] = "lib/skywalking/span.lua",
    ["skywalking.tracing_context"] = "lib/skywalking/tracing_context.lua",
    ["skywalking.util"] = "lib/skywalking/util.lua",
    ["skywalking.dependencies.base64"] = "lib/skywalking/dependencies/base64.lua",
   }
}
