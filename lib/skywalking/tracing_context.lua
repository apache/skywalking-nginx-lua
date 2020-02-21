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

TracingContext = {
    trace_id,
    self_generated_trace_id,
    segment_id,
    is_noop = false,

    internal,
}

function TracingContext:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.trace_id = Util:newID()
    o.self_generated_trace_id = true
    o.segment_id = o.trace_id
    o.internal = Internal:new()
    o.internal.owner = o
    return o
end

function TracingContext:createEntrySpan(operationName)
end

-------------- Internal Object-------------
-- Internal Object hosts the methods for SkyWalking LUA internal APIs only.
Internal = {
    -- span id starts from 0
    span_id_seq,
    -- Owner means the Context instance holding this Internal object.
    owner,
    -- The first created span.
    first_span,
    -- Lists
    -- Created span and still active
    active_spans,
    -- Finished spans
    finished_spans,
}

-- Create an internal instance
function Internal:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.span_id_seq = 0
    o.active_spans = {}
    o.finished_spans = {}

    return o
end

function Internal:addActive(span)
    if first_span == nil then
        first_span = span
    end
    table.insert(self.active_spans, span)
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