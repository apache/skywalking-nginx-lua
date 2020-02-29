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

local _M = {}

-------------- Internal Object-------------
-- Internal Object hosts the methods for SkyWalking LUA internal APIs only.
-- local Internal = {
--     self_generated_trace_id,
--     -- span id starts from 0
--     span_id_seq,
--     -- Owner means the Context instance holding this Internal object.
--     owner,
--     -- The first created span.
--     first_span,
--     -- The first ref injected in this context
--     first_ref,
--     -- Created span and still active
--     active_spans,
--     active_count,
--     -- Finished spans
--     finished_spans,
-- }

-- Create an internal instance
function _M.new()
    local internal = {}

    internal.self_generated_trace_id = true
    internal.span_id_seq = 0
    internal.active_spans = {}
    internal.active_count = 0
    internal.finished_spans = {}

    return internal
end

-- add the segment ref if this is the first ref of this context
function _M.addRefIfFirst(internal, ref)
    if internal.self_generated_trace_id == true then
        internal.self_generated_trace_id = false
        internal.owner.trace_id = ref.trace_id
        internal.first_ref = ref
    end
end

function _M.addActive(internal, span)
    if internal.first_span == nil then
        internal.first_span = span
    end

    -- span id starts at 0, to fit LUA, we need to plus one.
    internal.active_spans[span.span_id + 1] = span
    internal.active_count = internal.active_count + 1
    return internal.owner
end

function _M.finishSpan(internal, span)
    -- span id starts at 0, to fit LUA, we need to plus one.
    internal.active_spans[span.span_id + 1] = nil
    internal.active_count = internal.active_count - 1
    internal.finished_spans[#internal.finished_spans + 1] = span

    return internal.owner
end

-- Generate the next span ID.
function _M.nextSpanID(internal)
    local nextSpanId = internal.span_id_seq
    internal.span_id_seq = internal.span_id_seq + 1
    return nextSpanId
end

return _M
