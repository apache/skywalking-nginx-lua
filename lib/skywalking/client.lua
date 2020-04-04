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
    local ERR = ngx.ERR    

    check = function(premature)
        if not premature then
            local instancePropertiesSubmitted = metadata_buffer:get('instancePropertiesSubmitted')
            if (instancePropertiesSubmitted == nil or instancePropertiesSubmitted == false) then
                self:registerService(metadata_buffer, backend_http_uri)
            else
                self:ping(metadata_buffer, backend_http_uri)
            end

            self:reportTraces(metadata_buffer, backend_http_uri)

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
    local serviceInstanceName = metadata_buffer:get('serviceInstanceName')

    local cjson = require('cjson')
    local reportInstance = require("register").newReportInstanceProperties(serviceName, serviceInstanceName)
    local reportInstanceParam = cjson.encode(reportInstance)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/v3/management/reportProperties', {
        method = "POST",
        body = reportInstanceParam,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if not res then
        log(ERR, "Instance report fails, " .. err)
    elseif res.status == 200 then
        log(DEBUG, "Instance report response = " .. res.body)
        metadata_buffer:set('instancePropertiesSubmitted', true)
    else
        log(ERR, "Service register fails, response code " .. res.status)
    end
end

-- Ping the backend to update instance heartheat
function Client:ping(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local serviceName = metadata_buffer:get('serviceName')
    local serviceInstanceName = metadata_buffer:get('serviceInstanceName')

    local cjson = require('cjson')
    local pingPkg = require("register").newServiceInstancePingPkg(serviceName, serviceInstanceName)
    local pingPkgParam = cjson.encode(pingPkg)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/v3/management/keepAlive', {
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
        local res, err = httpc:request_uri(backend_http_uri .. '/v3/segments', {
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
        log(DEBUG, count,  " segments reported.")
    end
end

return Client
