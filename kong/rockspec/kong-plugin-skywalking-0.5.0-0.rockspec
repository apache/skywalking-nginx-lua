package = "kong-plugin-skywalking"
version = "0.5.0-0"
source = {
   url = "git://github.com/apache/skywalking-nginx-lua",
   branch = "v0.5.0",
}

description = {
   summary = "The Nginx Lua agent for Apache SkyWalking",
   homepage = "https://github.com/apache/skywalking-nginx-lua",
   license = "Apache License 2.0"
}

dependencies = {
   "skywalking-nginx-lua >= 0.5.0"
}

build = {
   type = "builtin",
   modules = {
      ["kong.plugins.skywalking.handler"] = "kong/plugins/skywalking/handler.lua",
      ["kong.plugins.skywalking.schema"] = "kong/plugins/skywalking/schema.lua"
   }
}
