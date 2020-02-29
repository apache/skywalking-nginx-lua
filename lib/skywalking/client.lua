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

local Client = {}

-- Tracing timer does the service and instance register
-- After register successfully, it sends traces and heart beat
function Client:startBackendTimer(backend_http_uri)
    local metadata_buffer = ngx.shared.tracing_buffer

    -- The codes of timer setup is following the OpenResty timer doc
    local delay = 3  -- in seconds
    local new_timer = ngx.timer.at
    local check

    local log = ngx.log
    local DEBUG = ngx.DEBUG

    check = function(premature)
        if not premature then
            local serviceId = metadata_buffer:get('serviceId')
            if (serviceId == nil or serviceId == 0) then
                self:registerService(metadata_buffer, backend_http_uri)
            end

            -- Register is in the async way, if register successfully, go for instance register
            serviceId = metadata_buffer:get('serviceId')
            if (serviceId ~= nil and serviceId ~= 0) then
                local serviceInstId = metadata_buffer:get('serviceInstId')
                if (serviceInstId == nil or serviceInstId == 0)  then
                    self:registerServiceInstance(metadata_buffer, backend_http_uri)
                end
            end

            -- After all register successfully, begin to send trace segments
            local serviceInstId = metadata_buffer:get('serviceInstId')
            if (serviceInstId ~= nil and serviceInstId ~= 0) then
                self:reportTraces(metadata_buffer, backend_http_uri)
                self:ping(metadata_buffer, backend_http_uri)
            end

            -- do the health check
            local ok, err = new_timer(delay, check)
            if not ok then
                log(ERR, "failed to create timer: ", err)
                return
            end
        end
    end

    if 0 == ngx.worker.id() then
        local ok, err = new_timer(delay, check)
        if not ok then
            log(ERR, "failed to create timer: ", err)
            return
        end
    end
end

-- Register service
function Client:registerService(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local serviceName = metadata_buffer:get('serviceName')
    
    local cjson = require('cjson')
    local serviceRegister = require("register"):newServiceRegister(serviceName)
    local serviceRegisterParam = cjson.encode(serviceRegister)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/v2/service/register', {
        method = "POST",
        body = serviceRegisterParam,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if not res then
        log(ERR, "Service register fails, " .. err)
    elseif res.status == 200 then
        log(DEBUG, "Service register response = " .. res.body)
        local registerResults = cjson.decode(res.body)

        for i, result in ipairs(registerResults)
        do
            if result.key == serviceName then
                local serviceId = result.value 
                log(DEBUG, "Service registered, service id = " .. serviceId)
                metadata_buffer:set('serviceId', serviceId)
            end
        end
    else
        log(ERR, "Service register fails, response code " .. res.status)
    end
end

-- Register service instance
function Client:registerServiceInstance(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local serviceInstName = 'name:' .. metadata_buffer:get('serviceInstanceName')
    metadata_buffer:set('serviceInstanceUUID', serviceInstName)

    local cjson = require('cjson')
    local serviceInstanceRegister = require("register"):newServiceInstanceRegister(
        metadata_buffer:get('serviceId'), 
        serviceInstName, 
        ngx.now() * 1000)
    local serviceInstanceRegisterParam = cjson.encode(serviceInstanceRegister)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/v2/instance/register', {
        method = "POST",
        body = serviceInstanceRegisterParam,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if err == nil then
        if res.status == 200 then
            log(DEBUG, "Service Instance register response = " .. res.body)
            local registerResults = cjson.decode(res.body)

            for i, result in ipairs(registerResults)
            do
                if result.key == serviceInstName then
                    local serviceId = result.value 
                    log(DEBUG, "Service Instance registered, service instance id = " .. serviceId)
                    metadata_buffer:set('serviceInstId', serviceId)
                end
            end
        else
            log(ERR, "Service Instance register fails, response code " .. res.status)
        end
    else
        log(ERR, "Service Instance register fails, " .. err)
    end
end

-- Ping the backend to update instance heartheat
function Client:ping(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local cjson = require('cjson')
    local pingPkg = require("register"):newServiceInstancePingPkg(
        metadata_buffer:get('serviceInstId'), 
        metadata_buffer:get('serviceInstanceUUID'), 
        ngx.now() * 1000)
    local pingPkgParam = cjson.encode(pingPkg)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/v2/instance/heartbeat', {
        method = "POST",
        body = pingPkgParam,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if err == nil then
        if res.status ~= 200 then
            log(ERR, "Agent ping fails, response code " .. res.status)
        end
    else
        log(ERR, "Agent ping fails, " .. err)
    end
end

-- Report trace segments to the backend
function Client:reportTraces(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local queue = ngx.shared.tracing_buffer
    local segment = queue:rpop('segment')

    local count = 0;

    local http = require('resty.http')
    local httpc = http.new()

    while segment ~= nil
    do
        local res, err = httpc:request_uri(backend_http_uri .. '/v2/segments', {
            method = "POST",
            body = segment,
            headers = {
                ["Content-Type"] = "application/json",
            },
        })
        
        if err == nil then
            if res.status ~= 200 then
                log(ERR, "Segment report fails, response code " .. res.status)
                break
            else
                count = count + 1
            end
        else
            log(ERR, "Segment report fails, " .. err)
            break
        end

        segment = queue:rpop('segment')
    end

    if count > 0 then
        log(ERR, count,  " segments reported.")
    end
end

return Client