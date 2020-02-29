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

local Util = require('util')
local Span = require('span')
local Segment = require('segment')
local TC_Internal = require('tracing_context_internal')

local _M = {}

-- local TracingContext = {
--     trace_id,
--     segment_id,
--     service_id,
--     service_inst_id,
--     is_noop = false,
--     internal,
-- }

function _M.newNoOP()
    return {is_noop = true}
end

function _M.new(serviceId, serviceInstID)
    if serviceInstID == nil then
        return _M.newNoOP()
    end

    local tracing_context = {}
    tracing_context.trace_id = Util.newID()
    tracing_context.segment_id = tracing_context.trace_id
    tracing_context.service_id = serviceId
    tracing_context.service_inst_id = serviceInstID
    tracing_context.internal = TC_Internal.new()
    tracing_context.internal.owner = tracing_context
    return tracing_context
end

-- Delegate to Span:createEntrySpan
-- @param contextCarrier could be nil if there is no downstream propagated context
function _M.createEntrySpan(tracingContext, operationName, parent, contextCarrier)
    if tracingContext.is_noop then
        return Span:newNoOP()
    end

    return Span:createEntrySpan(operationName, self, parent, contextCarrier)
end

-- Delegate to Span:createExitSpan
-- @param contextCarrier could be nil if don't need to inject any context to propagate
function _M.createExitSpan(tracingContext, operationName, parent, peer, contextCarrier)
    if tracingContext.is_noop then
        return Span:newNoOP()
    end

    return Span:createExitSpan(operationName, self, parent, peer, contextCarrier)
end

-- After all active spans finished, this segment will be treated as finished status.
-- Notice, it is different with Java agent, a finished context is still able to recreate new span, and be checked as finished again.
-- This gives the end user more flexibility. Unless it is a real reasonable case, don't call #drainAfterFinished multiple times.
--
-- Return (boolean isSegmentFinished, Segment segment).
-- Segment has value only when the isSegmentFinished is true
-- if isSegmentFinished == false, SpanList = nil
function _M.drainAfterFinished(tracingContext)
    if tracingContext.is_noop then
        return true, Segment:new()
    end

    if tracingContext.internal.active_count ~= 0 then
        return false, nil
    else
        local segment = Segment:new()
        segment.trace_id = tracingContext.trace_id
        segment.segment_id = tracingContext.segment_id
        segment.service_id = tracingContext.service_id
        segment.service_inst_id = tracingContext.service_inst_id
        segment.spans = tracingContext.internal.finished_spans
        return true, segment
    end
end

return _M
