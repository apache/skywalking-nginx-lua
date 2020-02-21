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

TestTracingContext = {}
    function TestTracingContext:testNew()
        local context = TC:new(1)
        lu.assertNotNil(context)
        lu.assertNotNil(context.segment_id[1])
        lu.assertNotNil(context.segment_id[2])
        lu.assertNotNil(context.segment_id[3])

        lu.assertEquals(context.trace_id, context.segment_id)
    end

    function TestTracingContext:testInternal_NextSpanSeqID()
        local context = TC:new(1)

        lu.assertEquals(context.internal:nextSpanID(), 0)
    end

    function TestTracingContext:testInternal_addActive()
        local context = TC:new(1)

        local mockSpan = {span_id = 0}
        context.internal:addActive(mockSpan)

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestTracingContext:testSpanStack()
        local context = TC:new(1)
        local span1 = context:createEntrySpan('entry_op')
        local span2 = context:createExitSpan("exit_op", span1, "127.0.0.1")

        local activeSpans = context.internal.active_spans
        local finishedSpans = context.internal.finished_spans
        lu.assertEquals(#(activeSpans), 2)
        lu.assertEquals(#(finishedSpans), 0)

        lu.assertEquals(span1, activeSpans[1])
        lu.assertEquals(span2, activeSpans[2])
    end
-- end TestTracingContext


os.exit( lu.LuaUnit.run() )
