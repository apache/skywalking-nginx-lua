package = "kong-plugin-skywalking"
version = "master-0"
source = {
   url = "git://github.com/apache/skywalking-nginx-lua",
   branch = "kong",
}

description = {
   summary = "The Nginx Lua agent for Apache SkyWalking",
   homepage = "https://github.com/apache/skywalking-nginx-lua",
   license = "Apache License 2.0"
}

dependencies = {
   "skywalking-nginx-lua >= master"
}

build = {
   type = "builtin",
   modules = {
      ["kong.plugins.skywalking.handler"] = "kong/plugins/skywalking/handler.lua",
      ["kong.plugins.skywalking.schema"] = "kong/plugins/skywalking/schema.lua"
   }
}
