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

-- Segment represents a finished tracing context
-- Including all information to send to the SkyWalking OAP server.
local Span = require('skywalking.span')
local Util = require('skywalking.util')

local _M = {}
-- local Segment = {
--     trace_id,
--     segment_id,
--     service,
--     service_instance,
--     spans,
-- }

-- Due to nesting relationship inside Segment/Span/TracingContext at the runtime,
-- SegmentProtocol is created to prepare JSON format serialization.
-- Following SkyWalking official trace protocol v3
-- https://github.com/apache/skywalking-data-collect-protocol/blob/master/language-agent/Tracing.proto
-- local SegmentProtocol = {
--     traceId,
--     traceSegmentId,
--     service,
--     serviceInstance,
--     spans,
-- }

-- Return SegmentProtocol
function _M.transform(segment)
    local segmentBuilder = Util.tablepool_fetch()
    segmentBuilder.traceId = segment.trace_id
    segmentBuilder.traceSegmentId = segment.segment_id
    segmentBuilder.service = segment.service
    segmentBuilder.serviceInstance = segment.service_instance

    segmentBuilder.spans = Util.tablepool_fetch()

    if segment.spans ~= nil and #segment.spans > 0 then
        for _, span in ipairs(segment.spans) do
            segmentBuilder.spans[#segmentBuilder.spans + 1] = Span.transform(span)
        end
    end

    return segmentBuilder
end

return _M
