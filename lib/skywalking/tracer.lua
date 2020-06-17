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
local Span = require('span')

local Tracer = {}

function Tracer:start(upstream_name, correlation, agent_namespace)
    local metadata_buffer = ngx.shared.tracing_buffer
    local TC = require('tracing_context')
    local Layer = require('span_layer')

    local nameSpace = ""
    if agent_namespace ~= nil then
        nameSpace = agent_namespace .. "-"
    end

    local tracingContext
    local serviceName = metadata_buffer:get("serviceName")
    local serviceInstanceName = metadata_buffer:get('serviceInstanceName')
    tracingContext = TC.new(serviceName, serviceInstanceName)

    -- Constant pre-defined in SkyWalking main repo
    -- 6000 represents Nginx
    local nginxComponentId = 6000

    local contextCarrier = {}
    contextCarrier[nameSpace .. "sw8"] = ngx.req.get_headers()[nameSpace .. "sw8"]
    contextCarrier[nameSpace .. "sw8-correlation"] = ngx.req.get_headers()[nameSpace .. "sw8-correlation"]
    local entrySpan = TC.createEntrySpan(tracingContext, ngx.var.uri, nil, contextCarrier, agent_namespace)
    Span.start(entrySpan, ngx.now() * 1000)
    Span.setComponentId(entrySpan, nginxComponentId)
    Span.setLayer(entrySpan, Layer.HTTP)

    Span.tag(entrySpan, 'http.method', ngx.req.get_method())
    Span.tag(entrySpan, 'http.params', ngx.var.scheme .. '://' .. ngx.var.host .. ngx.var.request_uri )

    contextCarrier = {}
    -- Use the same URI to represent incoming and forwarding requests
    -- Change it if you need.
    local upstreamUri = ngx.var.uri

    local upstreamServerName = upstream_name
    ------------------------------------------------------
    local exitSpan = TC.createExitSpan(tracingContext, upstreamUri, entrySpan, upstreamServerName, contextCarrier, correlation, agent_namespace)
    Span.start(exitSpan, ngx.now() * 1000)
    Span.setComponentId(exitSpan, nginxComponentId)
    Span.setLayer(exitSpan, Layer.HTTP)

    for name, value in pairs(contextCarrier) do
        ngx.req.set_header(name, value)
    end

    -- Push the data in the context
    ngx.ctx.tracingContext = tracingContext
    ngx.ctx.entrySpan = entrySpan
    ngx.ctx.exitSpan = exitSpan
end

function Tracer:finish()
    -- Finish the exit span when received the first response package from upstream
    if ngx.ctx.exitSpan ~= nil then
        Span.finish(ngx.ctx.exitSpan, ngx.now() * 1000)
        ngx.ctx.exitSpan = nil
    end
end

function Tracer:prepareForReport()
    local TC = require('tracing_context')
    local Segment = require('segment')
    if ngx.ctx.entrySpan ~= nil then
        Span.finish(ngx.ctx.entrySpan, ngx.now() * 1000)
        local status, segment = TC.drainAfterFinished(ngx.ctx.tracingContext)
        if status then
            local segmentJson = require('cjson').encode(Segment.transform(segment))
            ngx.log(ngx.DEBUG, 'segment = ', segmentJson)

            local queue = ngx.shared.tracing_buffer
            local length = queue:lpush('segment', segmentJson)
            ngx.log(ngx.DEBUG, 'segment buffer size = ', queue:llen('segment'))
        end
    end
end

return Tracer
