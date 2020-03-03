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
local Span = require('span')

local _M = {}
-- local Segment = {
--     trace_id,
--     segment_id,
--     service_id,
--     service_inst_id,
--     spans,
-- }

-- Due to nesting relationship inside Segment/Span/TracingContext at the runtime,
-- SegmentProtocol is created to prepare JSON format serialization.
-- Following SkyWalking official trace protocol v2
-- https://github.com/apache/skywalking-data-collect-protocol/blob/master/language-agent-v2/trace.proto
-- local SegmentProtocol = {
--     globalTraceIds,
--     traceSegmentId,
--     serviceId,
--     serviceInstanceId,
--     spans,
-- }

-- Return SegmentProtocol
function _M.transform(segment)
    local segmentBuilder = {}
    segmentBuilder.serviceId = segment.service_id
    segmentBuilder.globalTraceIds = {}
    segmentBuilder.globalTraceIds[1] = {idParts = segment.trace_id}
    segmentBuilder.traceSegmentId = {idParts = segment.segment_id}
    segmentBuilder.serviceId = segment.service_id
    segmentBuilder.serviceInstanceId = segment.service_inst_id

    segmentBuilder.spans = {}

    if segment.spans ~= nil and #segment.spans > 0 then
        for i, span in ipairs(segment.spans)
        do
            segmentBuilder.spans[#segmentBuilder.spans + 1] = Span.transform(span)
        end
    end

    return segmentBuilder
end

return _M
