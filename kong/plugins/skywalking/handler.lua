--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local tracer = require("skywalking.tracer")
local client = require("skywalking.client")
local Span = require('skywalking.span')

local SkyWalkingHandler = {
    PRIORITY = 100001,
    VERSION = "0.0.1",
}

function SkyWalkingHandler:init_worker()
    require("skywalking.util").set_randomseed()
end

function SkyWalkingHandler:access(config)
    if not client:isInitialized() then
        local metadata_buffer = ngx.shared.tracing_buffer
        metadata_buffer:set('serviceName', config.service_name)
        metadata_buffer:set('serviceInstanceName', config.service_instance_name)
        metadata_buffer:set('includeHostInEntrySpan', config.include_host_in_entry_span)

        client:startBackendTimer(config.backend_http_uri)
    end
    tracer:start(kong.request.get_forwarded_host())
end

function SkyWalkingHandler:body_filter(config)
    if ngx.arg[2] then
        local entrySpan = ngx.ctx.entrySpan
        Span.tag(entrySpan, 'kong.node', kong.node.get_hostname())

        local service = kong.router.get_service()
        if service and service.id then
            Span.tag(entrySpan, 'kong.service', service.id)
            local route = kong.router.get_route()
            if route and route.id then
                Span.tag(entrySpan, "kong.route", route.id)
            end
            if type(service.name) == "string" then
                Span.tag(entrySpan, "kong.service_name", service.name)
            end
        end

        tracer:finish()
    end
end

function SkyWalkingHandler:log(config)
    tracer:prepareForReport()
end

return SkyWalkingHandler