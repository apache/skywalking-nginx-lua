package = "kong-plugins-skywalking"
version = "master-0"
source = {
   url = "git://github.com/dmsolr/skywalking-nginx-lua",
   branch = "kong",
}

description = {
   summary = "The Nginx Lua agent for Apache SkyWalking",
   homepage = "https://github.com/apache/skywalking-nginx-lua",
   license = "Apache License 2.0"
}

dependencies = {
   "lua-resty-http >= 0.15",
   "lua-resty-jit-uuid >= 0.0.7",
   "skywalking-nginx-lua >= master"
}

build = {
   type = "builtin",
   modules = {
      ["kong.plugins.skywalking.handler"] = "kong/plugins/skywalking/handler.lua",
      ["kong.plugins.skywalking.schema"] = "kong/plugins/skywalking/schema.lua"
   }
}
