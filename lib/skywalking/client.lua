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
local Const = require('skywalking.constants')


local ngx = ngx
local SEGMENT_BATCH_COUNT = 100

local Client = {
    -- expose the delay for test
    backendTimerDelay = 3 -- in seconds 
}

local initialized = false

-- Tracing timer reports instance properties report, keeps alive and sends traces
-- After report instance properties successfully, it sends keep alive packages.
function Client:startBackendTimer(backend_http_uri)
    initialized = true
    local metadata_buffer = ngx.shared.tracing_buffer

    -- The codes of timer setup is following the OpenResty timer doc
    local new_timer = ngx.timer.at
    local check

    local log = ngx.log
    local ERR = ngx.ERR

    check = function(premature)
        if not premature and not self.stopped then
            local instancePropertiesSubmitted = metadata_buffer:get('instancePropertiesSubmitted')
            if (instancePropertiesSubmitted == nil or instancePropertiesSubmitted == false) then
                self:reportServiceInstance(metadata_buffer, backend_http_uri)
            else
                self:ping(metadata_buffer, backend_http_uri)
            end

            self:reportTraces(metadata_buffer, backend_http_uri)

            -- do the health check
            local ok, err = new_timer(self.backendTimerDelay, check)
            if not ok then
                log(ERR, "failed to create timer: ", err)
                return
            end
        end
    end

    if 0 == ngx.worker.id() then
        local ok, err = new_timer(self.backendTimerDelay, check)
        if not ok then
            log(ERR, "failed to create timer: ", err)
            return
        end
    end
end

function Client:isInitialized()
    return initialized
end

-- Stop the tracing report timer and clean unreported data
function Client:destroyBackendTimer()
    self.stopped = true

    local metadata_buffer = ngx.shared.tracing_buffer
    local ok, err = metadata_buffer:delete(Const.segment_queue)
    if not ok then
        return nil, err
    end
    
    return true
end

function Client:reportServiceInstance(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG
    local ERR = ngx.ERR

    local serviceName = metadata_buffer:get('serviceName')
    local serviceInstanceName = metadata_buffer:get('serviceInstanceName')

    local cjson = require('cjson')
    local reportInstance = require("skywalking.management").newReportInstanceProperties(serviceName, serviceInstanceName)
    local reportInstanceParam, err = cjson.encode(reportInstance)
    if err then
        log(ERR, "Request to report instance fails, ", err)
        return
    end

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
        log(ERR, "Instance report fails, ", err)
    elseif res.status == 200 then
        log(DEBUG, "Instance report response = ", res.body)
        metadata_buffer:set('instancePropertiesSubmitted', true)
    else
        log(ERR, "Instance report fails, response code ", res.status)
    end
end

-- Ping the backend to update instance heartheat
function Client:ping(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local ERR = ngx.ERR

    local serviceName = metadata_buffer:get('serviceName')
    local serviceInstanceName = metadata_buffer:get('serviceInstanceName')

    local cjson = require('cjson')
    local pingPkg = require("skywalking.management").newServiceInstancePingPkg(serviceName, serviceInstanceName)
    local pingPkgParam, err = cjson.encode(pingPkg)
    if err then
        log(ERR, "Agent ping fails, ", err)
    end

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
            log(ERR, "Agent ping fails, response code ", res.status)
        end
    else
        log(ERR, "Agent ping fails, ", err)
    end
end

-- Send segemnts data to backend
local function sendSegments(segmentTransform, backend_http_uri)
    local log = ngx.log
    local ERR = ngx.ERR

    local http = require('resty.http')
    local httpc = http.new()

    local res, err = httpc:request_uri(backend_http_uri .. '/v3/segments', {
        method = "POST",
        body = segmentTransform,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if err == nil then
        if res.status ~= 200 then
            log(ERR, "Segment report fails, response code ", res.status)
            return false
        end
    else
        log(ERR, "Segment report fails, ", err)
        return false
    end

    return true
end

-- Report trace segments to the backend
function Client:reportTraces(metadata_buffer, backend_http_uri)
    local log = ngx.log
    local DEBUG = ngx.DEBUG

    local queue = ngx.shared.tracing_buffer
    local segment = queue:rpop(Const.segment_queue)
    local segmentTransform = ''

    local count = 0
    local totalCount = 0

    while segment ~= nil
    do
        if #segmentTransform > 0 then
            segmentTransform = segmentTransform .. ','
        end

        segmentTransform = segmentTransform .. segment
        segment = queue:rpop(Const.segment_queue)
        count = count + 1

        if count >= SEGMENT_BATCH_COUNT then
            if sendSegments('[' .. segmentTransform .. ']', backend_http_uri) then
                totalCount = totalCount + count
            end

            segmentTransform = ''
            count = 0
        end
    end

    if #segmentTransform > 0 then
        if sendSegments('[' .. segmentTransform .. ']', backend_http_uri) then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        log(DEBUG, totalCount,  " segments reported.")
    end
end

return Client
