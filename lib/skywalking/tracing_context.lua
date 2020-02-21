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

TracingContext = {
    trace_id,
    segment_id,
    service_inst_id,

    is_noop = false,

    internal,
}

function TracingContext:new(serviceInstID)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    if serviceInstID == nil then
        return nil
    end

    o.trace_id = Util:newID()
    o.segment_id = o.trace_id
    o.service_inst_id = serviceInstID
    o.internal = Internal:new()
    o.internal.owner = o
    return o
end

-- Delegate to Span:createEntrySpan
-- @param contextCarrier could be nil if there is no downstream propagated context
function TracingContext:createEntrySpan(operationName, parent, contextCarrier)
    return Span:createEntrySpan(operationName, self, parent, contextCarrier)
end

-- Delegate to Span:createExitSpan
-- @param contextCarrier could be nil if don't need to inject any context to propagate
function TracingContext:createExitSpan(operationName, parent, peer, contextCarrier)
    return Span:createExitSpan(operationName, self, parent, peer, contextCarrier)
end

-------------- Internal Object-------------
-- Internal Object hosts the methods for SkyWalking LUA internal APIs only.
Internal = {
    self_generated_trace_id,
    -- span id starts from 0
    span_id_seq,
    -- Owner means the Context instance holding this Internal object.
    owner,
    -- The first created span.
    first_span,
    -- The first ref injected in this context
    first_ref,
    -- Created span and still active
    active_spans,
    active_count,
    -- Finished spans
    finished_spans,
}

-- Create an internal instance
function Internal:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.self_generated_trace_id = true
    o.span_id_seq = 0
    o.active_spans = {}
    o.active_count = 0
    o.finished_spans = {}

    return o
end

-- add the segment ref if this is the first ref of this context
function Internal:addRefIfFirst(ref)
    if self.self_generated_trace_id == true then
        self.self_generated_trace_id = false
        self.owner.trace_id = ref.trace_id
        self.first_ref = ref
    end
end

function Internal:hasRef()
    return first_ref ~= nil
end

function Internal:getFirstRef()
    return first_ref
end

function Internal:addActive(span)
    if self.first_span == nil then
        self.first_span = span
    end

    -- span id starts at 0, to fit LUA, we need to plus one.    
    self.active_spans[span.span_id + 1] = span
    self.active_count = self.active_count + 1
    return self.owner
end

function Internal:finishSpan(span)
    -- span id starts at 0, to fit LUA, we need to plus one.
    self.active_spans[span.span_id + 1] = nil
    self.active_count = self.active_count - 1
    table.insert(self.finished_spans, span)
    return self.owner
end

-- Generate the next span ID.
function Internal:nextSpanID()
    local nextSpanId = self.span_id_seq
    self.span_id_seq = self.span_id_seq + 1;
    return nextSpanId
end
---------------------------------------------

return TracingContext