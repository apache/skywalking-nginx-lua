Apache SkyWalking Nginx Agent
==========

<img src="http://skywalking.apache.org/assets/logo.svg" alt="Sky Walking logo" height="90px" align="right" />

[![Twitter Follow](https://img.shields.io/twitter/follow/asfskywalking.svg?style=for-the-badge&label=Follow&logo=twitter)](https://twitter.com/AsfSkyWalking)

![CI](https://github.com/apache/skywalking-nginx-lua/workflows/CI/badge.svg?branch=master)


[**SkyWalking**](https://github.com/apache/skywalking) Nginx Agent provides the native tracing capability for Nginx powered by Nginx LUA module.

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
        -- Instance means the number of Nginx deployment, does not mean the worker instances
        metadata_buffer:set('serviceInstanceName', 'User Service Instance Name')

        require("client"):startBackendTimer("http://127.0.0.1:12800")
    }

    server {
        listen 8080;

        location /ingress {
            default_type text/html;

            rewrite_by_lua_block {
                ------------------------------------------------------
                -- NOTICE, this should be changed manually
                -- This variable represents the upstream logic address
                -- Please set them as service logic name or DNS name
                --
                -- Currently, we can not have the upstream real network address
                -- The parameter "customer_namespace" for java agent config "agent.namespace"
                ------------------------------------------------------
                require("tracer"):start("upstream service", "customer_namespace")
            }

            -- Target upstream service
            proxy_pass http://127.0.0.1:8080/backend;

            body_filter_by_lua_block {
                if ngx.arg[2] then
                    require("tracer"):finish()
                end
            }

            log_by_lua_block {
                require("tracer"):prepareForReport()
            }
        }
    }
}
```

# Download
Please head to the [releases page](http://skywalking.apache.org/downloads/) to download a release of Apache SkyWalking.

# Compatible backend
SkyWalking OAP begins to support LUA agent in 7.0.0 release. 

You could choose master branch before the official 7.0.0 release.

# Set up dev env
### Debug Startup
By using the `/examples/nginx.conf`, you could start the Nginx with LUA module or OpenResty. Such as `nginx -c /path/to/skywalking-nginx-lua/examples/nginx.conf`
Then you could
1. See the `register logs` happens on the console log.
```
2020/02/27 09:22:06 [debug] 20676#11799235: *4 [lua] content_by_lua(nginx.conf:118):4: Service register request = {"services":[{"type":"normal","serviceName":"User Service Name"}]}
2020/02/27 09:22:06 [debug] 20676#11799235: *2 [lua] client.lua:99: registerService(): Service register response = [{"key":"User Service Name","value":1}]

2020/02/27 09:22:06 [debug] 20676#11799235: *2 [lua] client.lua:106: registerService(): Service registered, service id = 1
2020/02/27 09:22:06 [debug] 20676#11799235: *4 [lua] content_by_lua(nginx.conf:134):3: Service instance register request = {"instances":[{"time":1582766526928,"instanceUUID":"name:User Service Instance Name","properties":[{"key":"language","value":"Lua"}],"serviceId":1}]}
2020/02/27 09:22:06 [debug] 20676#11799235: *2 [lua] client.lua:143: registerServiceInstance(): Service Instance register response = [{"key":"name:User Service Instance Name","value":1}]
2020/02/27 09:22:06 [debug] 20676#11799235: *2 [lua] client.lua:150: registerServiceInstance(): Service Instance registered, service instance id = 1
```

2. Access the `http://127.0.0.1:8080/ingress` then you could see the tracing happens and reported spans in the logs.
```
2020/02/27 09:22:10 [debug] 20676#11799235: *9 [lua] tracer.lua:91: prepareForReport(): segment = {"spans":[{"operationName":"\/tier2\/lb","startTime":1582766530125,"endTime":1582766530139,"spanType":"Exit","spanId":1,"isError":false,"parentSpanId":0,"componentId":6000,"peer":"User Service Name-nginx:upstream_ip:port","spanLayer":"HTTP"},{"operationName":"\/tier2\/lb","startTime":1582766530125,"tags":[{"key":"http.method","value":"GET"},{"key":"http.params","value":"http:\/\/127.0.0.1\/tier2\/lb"}],"endTime":1582766530139,"spanType":"Entry","spanId":0,"isError":false,"parentSpanId":-1,"componentId":6000,"refs":[{"parentTraceSegmentId":{"idParts":[1582766530044,794206293,69887]},"parentEndpointId":0,"entryEndpointId":0,"parentServiceInstanceId":1,"parentEndpoint":"\/ingress","networkAddress":"#User Service Name-nginx:upstream_ip:port","parentSpanId":1,"entryServiceInstanceId":1,"networkAddressId":0,"entryEndpoint":"\/ingress"}],"spanLayer":"HTTP"}],"serviceInstanceId":1,"serviceId":1,"traceSegmentId":{"idParts":[1582766530052,794206293,69887]},"globalTraceIds":[{"idParts":[1582766530044,794206293,69887]}]}
2020/02/27 09:22:10 [debug] 20676#11799235: *9 [lua] tracer.lua:95: prepareForReport(): segment buffer size = 1
2020/02/27 09:22:10 [debug] 20676#11799235: *6 [lua] tracer.lua:91: prepareForReport(): segment = {"spans":[{"operationName":"\/ingress","startTime":1582766530114,"endTime":1582766530140,"spanType":"Exit","spanId":1,"isError":false,"parentSpanId":0,"componentId":6000,"peer":"User Service Name-nginx:upstream_ip:port","spanLayer":"HTTP"},{"operationName":"\/ingress","startTime":1582766530114,"tags":[{"key":"http.method","value":"GET"},{"key":"http.params","value":"http:\/\/127.0.0.1\/ingress"}],"endTime":1582766530140,"spanType":"Entry","spanId":0,"parentSpanId":-1,"isError":false,"spanLayer":"HTTP","componentId":6000}],"serviceInstanceId":1,"serviceId":1,"traceSegmentId":{"idParts":[1582766530044,794206293,69887]},"globalTraceIds":[{"idParts":[1582766530044,794206293,69887]}]}
```

### Local Development and Unit Tests
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
- **startTimer**, `require("client"):startBackendTimer("http://127.0.0.1:12800")`. Start the skywalking backend timer. This timer register the metadata and report traces to the backend.
- **start**, `require("tracer"):start("upstream service", "agent_name_space")`. Begin the tracing before the upstream begin, use the name_space with java agent config "agent.namespace" .
- **finish**, `require("tracer"):finish()`. Finish the tracing for this HTTP request.
- **prepareForReport**, `require("tracer"):prepareForReport()`. Prepare the finished segment for further report.

## Tracing APIs at LUA level
**TracingContext** is the entrance API for lua level tracing.
- `TracingContext.new(serviceId, serviceInstID)`, create an active tracing context.
- `TracingContext.newNoOP()`, create a no OP tracing context.
- `TracingContext.drainAfterFinished()`, fetch the segment includes all finished spans.

Create 2 kinds of span
- `TracingContext.createEntrySpan(operationName, parent, contextCarrier)`
- `TracingContext.createExitSpan(operationName, parent, peer, contextCarrier)`


# Contact Us
* Submit an [issue](https://github.com/apache/skywalking/issues) with `[NIGNX-LUA]` as the issue title prefix.
* Mail list: **dev@skywalking.apache.org**. Mail to `dev-subscribe@skywalking.apache.org`, follow the reply to subscribe the mail list.
* Join `skywalking` channel at [Apache Slack](https://join.slack.com/t/the-asf/shared_invite/enQtNzc2ODE3MjI1MDk1LTAyZGJmNTg1NWZhNmVmOWZjMjA2MGUyOGY4MjE5ZGUwOTQxY2Q3MDBmNTM5YTllNGU4M2QyMzQ4M2U4ZjQ5YmY). If the link is not working, find the latest one at [Apache INFRA WIKI](https://cwiki.apache.org/confluence/display/INFRA/Slack+Guest+Invites).
* QQ Group: 392443393(2000/2000, not available), 901167865(available)

# Release Guide
All committers should follow [Release Guide](release.md) to publish the official release.

# License
Apache 2.0
