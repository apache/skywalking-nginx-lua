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

local lu = require('luaunit')
local TC = require('tracing_context')
local Span = require('span')
local SpanLayer = require("span_layer")

TestSpan = {}
    function TestSpan:testNewEntry()
        local context = TC:new(1)
        lu.assertNotNil(context)

        local span1 = Span:createEntrySpan("operation_name", context, nil, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, true)
        lu.assertEquals(span1.is_exit, false)
        lu.assertEquals(span1.layer, SpanLayer.NONE)

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestSpan:testNewEntryWithContextCarrier()
        local context = TC:new(1)
        lu.assertNotNil(context)

        -- Typical header from the SkyWalking Java Agent test case
        local header = {sw6='1-My40LjU=-MS4yLjM=-4-1-1-IzEyNy4wLjAuMTo4MDgw-Iy9wb3J0YWw=-MTIz'}

        local span1 = Span:createEntrySpan("operation_name", context, nil, header)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, true)
        lu.assertEquals(span1.is_exit, false)
        lu.assertEquals(span1.layer, SpanLayer.NONE)
        local ref = span1.refs[1]
        lu.assertNotNil(ref)
        lu.assertEquals(ref.trace_id, {3, 4, 5})
        -- Context trace id will be overrided by the ref trace id
        lu.assertEquals(context.trace_id, {3, 4, 5})
        lu.assertEquals(ref.segment_id, {1, 2, 3})
        lu.assertEquals(ref.span_id, 4)
        lu.assertEquals(ref.parent_service_instance_id, 1)
        lu.assertEquals(ref.entry_service_instance_id, 1)
        lu.assertEquals(ref.network_address, '127.0.0.1:8080')
        lu.assertEquals(ref.network_address_id, 0)
        lu.assertEquals(ref.entry_endpoint_name, '/portal')
        lu.assertEquals(ref.entry_endpoint_id, 0)
        lu.assertEquals(ref.parent_endpoint_name, nil)
        lu.assertEquals(ref.parent_endpoint_id, 123)

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestSpan:testNewExit()
        local context = TC:new(1)
        lu.assertNotNil(context)

        local contextCarrier = {}
        local span1 = Span:createExitSpan("operation_name", context, nil, '127.0.0.1:80', contextCarrier)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, false)
        lu.assertEquals(span1.is_exit, true)
        lu.assertEquals(span1.layer, SpanLayer.NONE)
        lu.assertEquals(span1.peer, '127.0.0.1:80')

        lu.assertEquals(#(context.internal.active_spans), 1)
        lu.assertNotNil(contextCarrier['sw6'])
    end

    function TestSpan:testNew()
        local context = TC:new(1)
        lu.assertNotNil(context)

        local span1 = Span:new("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.parent_span_id, -1)
        lu.assertEquals(span1.span_id, 0)
        lu.assertEquals(span1.operation_name, "operation_name")
        local span2 = Span:new("operation_name", context, span1)
        lu.assertEquals(span2.parent_span_id, 0)
        lu.assertEquals(span2.span_id, 1)
        lu.assertNotNil(span2.start_time)

        -- Use new context to check again
        context = TC:new(1)
        lu.assertNotNil(context)

        span1 = Span:new("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.parent_span_id, -1)
        lu.assertEquals(span1.span_id, 0)
    end

    function TestSpan:testProperties()
        local context = TC:new(1)

        local span1 = Span:new("operation_name", context, nil)
        span1:start(1234567)
        lu.assertEquals(span1.start_time, 1234567)
        span1:finish(2222222)
        lu.assertEquals(span1.end_time, 2222222)
        span1:finishWithDuration(123)
        lu.assertEquals(span1.end_time, 1234690)
    end
-- end TestSpan


os.exit( lu.LuaUnit.run() )