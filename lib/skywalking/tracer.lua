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

local Tracer = {}

function Tracer:startBackendTimer()
    local metadata_buffer = ngx.shared.tracing_buffer
    local TC = require('tracing_context')
    local Layer = require('span_layer')

    local tracingContext
    local serviceName = metadata_buffer:get("serviceName")
    local serviceInstId = metadata_buffer:get("serviceInstId")
    local serviceId = metadata_buffer:get('serviceId')
    if (serviceInstId ~= nil and serviceInstId ~= 0) then
        tracingContext = TC:new(serviceId, serviceInstId)
    else
        tracingContext = TC:newNoOP()
    end

    -- Constant pre-defined in SkyWalking main repo
    -- 84 represents Nginx
    local nginxComponentId = 6000

    local contextCarrier = {}
    contextCarrier["sw6"] = ngx.req.get_headers()["sw6"]
    local entrySpan = tracingContext:createEntrySpan(ngx.var.uri, nil, contextCarrier)
    entrySpan:start(ngx.now() * 1000)
    entrySpan:setComponentId(nginxComponentId)
    entrySpan:setLayer(Layer.HTTP)

    entrySpan:tag('http.method', ngx.req.get_method())
    entrySpan:tag('http.params', ngx.var.scheme .. '://' .. ngx.var.host .. ngx.var.request_uri )

    contextCarrier = {}
    -- Use the same URI to represent incoming and forwarding requests
    -- Change it if you need.
    local upstreamUri = ngx.var.uri
    ------------------------------------------------------
    -- NOTICE, this should be changed manually
    -- This variable represents the upstream logic address
    -- Please set them as service logic name or DNS name
    --
    -- TODO, currently, we can't have the upstream real network address
    ------------------------------------------------------
    local upstreamServerName = serviceName .. "-nginx:upstream_ip:port"
    ------------------------------------------------------
    local exitSpan = tracingContext:createExitSpan(upstreamUri, entrySpan, upstreamServerName, contextCarrier)
    exitSpan:start(ngx.now() * 1000)
    exitSpan:setComponentId(nginxComponentId)
    exitSpan:setLayer(Layer.HTTP)

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
        ngx.ctx.exitSpan:finish(ngx.now() * 1000)
        ngx.ctx.exitSpan = nil
    end
end

function Tracer:prepareForReport()
    if ngx.ctx.entrySpan ~= nil then
        ngx.ctx.entrySpan:finish(ngx.now() * 1000)
        local status, segment = ngx.ctx.tracingContext:drainAfterFinished()
        if status then
            local segmentJson = require('cjson').encode(segment:transform())
            ngx.log(ngx.DEBUG, 'segment = ' .. segmentJson)

            local queue = ngx.shared.tracing_buffer
            local length = queue:lpush('segment', segmentJson)
            ngx.log(ngx.DEBUG, 'segment buffer size = ' .. queue:llen('segment'))
        end
    end
end

return Tracer
