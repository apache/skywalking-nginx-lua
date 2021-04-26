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
local TC = require('skywalking.tracing_context')
local Span = require("skywalking.span")
local Segment = require("skywalking.segment")

local ngx = ngx
local prodcuer
local SEGMENT_BATCH_COUNT = 100

local Client = {
    -- expose the delay for test
    backend_timer_delay = 3 -- in seconds
}

local producer_config = {
    producer_type = "async",
    batch_num = SEGMENT_BATCH_COUNT,
    flush_time = Client.backend_timer_delay * 1000
}


function Client:start_backend_timer(broker_list)
    local metadata_buffer = ngx.shared.tracing_buffer

    producer = require('resty.kafka.producer'):new(broker_list, producer_config)

    local log = ngx.log
    local ERR = ngx.ERR

    -- The codes of timer setup is following the OpenResty timer doc
    local new_timer = ngx.timer.at
    local check
    check = function(premature)
        if not premature and not self.stopped then
            local instance_properties_submitted = metadata_buffer:get("instancePropertiesSubmitted")
            if (instance_properties_submitted) then
                self:ping(metadata_buffer, producer)
            else
                self:report_service_instance(metadata_buffer, producer)
            end

            -- do the health check
            local ok, err = new_timer(self.backend_timer_delay, check)
            if not ok then
                log(ERR, "failed to create timer: ", err)
                return
            end
        end
    end

    if 0 == ngx.worker.id() then
        local ok, err = new_timer(self.backend_timer_delay, check)
        if not ok then
            log(ERR, "failed to create timer: ", err)
            return
        end
    end
end


-- Stop the tracing report timer and clean unreported data
function Client:destroy_backend_timer()
    self.stopped = true

    local metadata_buffer = ngx.shared.tracing_buffer
    local ok, err = metadata_buffer:delete(Const.segment_queue)
    if not ok then
        return nil, err
    end

    return true
end


function Client:report_service_instance(metadata_buffer, producer)
    local log = ngx.log
    local ERR = ngx.ERR

    local service_name = metadata_buffer:get("serviceName")
    local service_instance_name = metadata_buffer:get("serviceInstanceName")

    local cjson = require('cjson')
    local report_instance = require('skywalking.management')
        .newReportInstanceProperties(service_name, service_instance_name)
    local instance = require("skywalking.kafka.proto_util")
        .instance_properties_transform(report_instance)

    local _, err = producer:send("skywalking-managements", "register-" .. service_instance_name, instance)
    if err then
        log(ERR, "Agent register fails, ", err)
        return false
    else
        return true
    end
end


-- Ping the backend to update instance heartheat
function Client:ping(metadata_buffer, producer)
    local log = ngx.log
    local ERR = ngx.ERR

    local service_name = metadata_buffer:get("serviceName")
    local service_instance_name = metadata_buffer:get("serviceInstanceName")

    local ping_pkg = require('skywalking.management').newServiceInstancePingPkg(service_name, service_instance_name)
    local instance_ping = require("skywalking.kafka.proto_util").instance_ping_transform(ping_pkg)

    local _, err = producer:send("skywalking-managements", service_instance_name, instance_ping)
    if err then
        log(ERR, "Agent ping fails, ", err)
        return false
    else
        return true
    end
end


function Client:report()
    local entrySpan = ngx.ctx.entrySpan
    if not entrySpan then
        return
    end

    local ngxstatus = ngx.var.status
    Span.tag(entrySpan, 'http.status', ngxstatus)
    if tonumber(ngxstatus) >= 500 then
        Span.errorOccurred(entrySpan)
    end

    Span.finish(entrySpan, ngx.now() * 1000)

    local ok, segment = TC.drainAfterFinished(ngx.ctx.tracingContext)
    if not ok then
        return
    end

    local proto_util = require("skywalking.kafka.proto_util")
    local segment_object = proto_util.segment_transform(Segment.transform(segment))

    local ok, err = producer:send("skywalking-segments", segment.trace_segment_id, segment_object)
    if not ok then
        ngx.log(ngx.ERR, "Segment report fails, ", err)
    end

    require("skywalking.util").tablepool_release()
end

return Client
