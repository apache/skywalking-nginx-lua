Apache SkyWalking Nginx Agent
==========

<img src="http://skywalking.apache.org/assets/logo.svg" alt="Sky Walking logo" height="90px" align="right" />

[![Twitter Follow](https://img.shields.io/twitter/follow/asfskywalking.svg?style=for-the-badge&label=Follow&logo=twitter)](https://twitter.com/AsfSkyWalking)

![CI](https://github.com/apache/skywalking-nginx-lua/workflows/CI/badge.svg?branch=master)


**SkyWalking** Nginx Agent provides the native tracing capability for Nginx powered by Nginx LUA module. 

This agent follows the SkyWalking tracing and header protocol. It reports tracing data to SkyWalking APM through HTTP protocol. 
All HTTP 1.1 requests go through Nginx could be collected by this agent.

# Setup Doc
```
http {
    lua_package_path "/Path/to/.../skywalking-nginx-lua/lib/skywalking/?.lua;;";

    # Buffer represents the register inform and the queue of the finished segment 
    lua_shared_dict tracing_buffer 100m;
    
    # Init is the timer setter and keeper
    # Setup an infinite loop timer to do register and trace report.
    init_worker_by_lua_block {
        local metadata_buffer = ngx.shared.tracing_buffer

        -- Set service name
        metadata_buffer:set('serviceName', 'User Service Name')
        -- Instance means the number of Nginx deloyment, does not mean the worker instances
        metadata_buffer:set('serviceInstanceName', 'User Service Instance Name')

        require("client"):startBackendTimer("http://127.0.0.1:8080")
    }

    server {
        listen 8080;

        location /ingress {
            default_type text/html;

            rewrite_by_lua_block {
                require("tracer"):start()
            }

            -- Target upstream service
            proxy_pass http://127.0.0.1:8080/backend;

            body_filter_by_lua_block {
                require("tracer"):finish()
            }

            log_by_lua_block {
                require("tracer"):prepareForReport()
            }
        }
    }
}
```

# Set up dev env
All codes in the `lib/skywalking` require the `*_test.lua` to do the UnitTest. To run that, you need to install
- Lua 5.3
- LuaRocks

The following libs are required in runtime or test cases, please use `LuaRocks` to install them.
- lua-cjson. NOTICE, some platforms such as MacOS 10.15 may have issue with the latest release of this lib, consider to install an old release.(`luarocks install lua-cjson 2.1.0-1`)
- luaunit

# APIs
This LUA tracing lib is originally designed for Nginx+LUA/OpenResty ecosystems. But we write it to support more complex cases.
If you just use this in the Ngnix, [Setup Doc](#setup-doc) should be good enough.
The following APIs are for developers or using this lib out of the Nginx case.

## Nginx APIs
- **startTimer**, `require("client"):startBackendTimer("http://127.0.0.1:8080")`. Start the backend timer. This timer register the metadata and report traces to the backend.
- **start**, `require("tracer"):start()`. Begin the tracing before the upstream begin.
- **finish**, `require("tracer"):finish()`. Finish the tracing for this HTTP request.
- **prepareForReport**, `require("tracer"):prepareForReport()`. Prepare the finished segment for further report.

## Tracing APIs at LUA level
**TracingContext** is the entrance API for lua level tracing.
- `TracingContext:new(serviceId, serviceInstID)`, create an active tracing context.
- `TracingContext:newNoOP()`, create a no OP tracing context.
- `TracingContext:drainAfterFinished()`, fetch the segment includes all finished spans.

Create 2 kinds of span
- `TracingContext:createEntrySpan(operationName, parent, contextCarrier)`
- `TracingContext:createExitSpan(operationName, parent, peer, contextCarrier)`


# Download
Have no release yet.

# Contact Us
* Submit an [issue](https://github.com/apache/skywalking/issues)
* Mail list: **dev@skywalking.apache.org**. Mail to `dev-subscribe@skywalking.apache.org`, follow the reply to subscribe the mail list.
* Join `skywalking` channel at [Apache Slack](https://join.slack.com/t/the-asf/shared_invite/enQtNzc2ODE3MjI1MDk1LTAyZGJmNTg1NWZhNmVmOWZjMjA2MGUyOGY4MjE5ZGUwOTQxY2Q3MDBmNTM5YTllNGU4M2QyMzQ4M2U4ZjQ5YmY). If the link is not working, find the latest one at [Apache INFRA WIKI](https://cwiki.apache.org/confluence/display/INFRA/Slack+Guest+Invites).
* QQ Group: 392443393(2000/2000, not available), 901167865(available)

# License
Apache 2.0