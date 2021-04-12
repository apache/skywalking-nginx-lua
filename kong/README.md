Apache SkyWalking Nginx Agent For Kong
==========

This plugin base on  Apache SkyWalking Nginx Agent for the Kong API gateway to integrate with the Apache SkyWalking distributed tracing system.

## Usage

1. Install the plugin on Kong:

To install kong-plugin-skywalking:
```bash
$ luarocks install kong-plugin-skywalking --local
```

Edit kong.conf:
```
plugins = bundled,skywalking

lua_package_path = ${user.home}/.luarocks/share/lua/5.1/?.lua;;
```

Set environment:
```
$ export KONG_NGINX_HTTP_LUA_SHARED_DICT="tracing_buffer 128m"
```

Restart Kong

2. Enabling & configuring plugin:

Add the plugin to an API:

```
$ curl -i -X POST \
   --url http://localhost:8001/apis/{api_name}/plugins/ \
   --data 'name=skywalking' \
   --data 'config.backend_http_uri=http://localhost:12800' \
   --data 'config.sample_ratio=100' \
   --data 'config.service_name=kong'
   --data 'config.service_instance_name=kong-with-skywalking'
``` 

Add the plugin to global:
```
$ curl -X POST --url http://localhost:8001/plugins/ \
   --data 'name=skywalking' \
   --data 'config.backend_http_uri=http://localhost:12800' \
   --data 'config.sample_ratio=100' \
   --data 'config.service_name=kong'
   --data 'config.service_instance_name=kong-with-skywalking'
```