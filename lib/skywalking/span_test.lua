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
        local context = TC:new()
        lu.assertNotNil(context)

        local span1 = Span:createEntrySpan("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.isEntry, true)
        lu.assertEquals(span1.isExit, false)
        lu.assertEquals(span1.layer, SpanLayer.NONE)

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestSpan:testNew()
        local context = TC:new()
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
        context = TC:new()
        lu.assertNotNil(context)

        span1 = Span:new("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.parent_span_id, -1)
        lu.assertEquals(span1.span_id, 0)
    end
-- end TestSpan


os.exit( lu.LuaUnit.run() )