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
function Client:startTimer(metadata_buffer, backend_http_uri)
    -- The codes of timer setup is following the OpenResty timer doc
    local delay = 3  -- in seconds
    local new_timer = ngx.timer.at
    local check

    local log = ngx.log
    local DEBUG = ngx.DEBUG

    check = function(premature)
        if not premature then
            if metadata_buffer['serviceId'] == nil then
                self:registerService(metadata_buffer, backend_http_uri)
            end

            -- Register is in the async way, if register successfully, go for instance register
            if metadata_buffer['serviceId'] ~= nil then
                if metadata_buffer['serviceInstId'] == nil then
                    
                end
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

    local serviceName = metadata_buffer['serviceName']
    local cjson = require('cjson')
    local serviceRegister = require("register").newServiceRegister(serviceName)
    local serviceRegisterParam = cjson.encode(serviceRegister)

    local http = require('resty.http')
    local httpc = http.new()
    local res, err = httpc:request_uri(backend_http_uri .. '/register/service', {
        method = "POST",
        body = serviceRegisterParam,
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if #res.body > 0 then
        local registerResults = cjson.decode(res.body)

        for i, result in ipairs(registerResults)
        do
            if result.key == serviceName then
                local serviceId = result.value 
                log(DEBUG, "Service registered, service id = " .. serviceId)
                metadata_buffer['serviceId'] = serviceId
            end
        end
    end
end

return Client