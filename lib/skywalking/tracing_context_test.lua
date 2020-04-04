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
local Segment = require('segment')
local Span = require('span')

TestTracingContext = {}
    function TestTracingContext:testNew()
        local context = TC.new("service", "instance")
        lu.assertNotNil(context)
        lu.assertNotNil(context.segment_id)

        lu.assertEquals(context.trace_id, context.segment_id)
    end

    function TestTracingContext:testInternal_NextSpanSeqID()
        local context = TC.new("service", "instance")

        lu.assertEquals(context.internal.nextSpanID(context.internal), 0)
    end

    function TestTracingContext:testInternal_addActive()
        local context = TC.new("service", "instance")

        local mockSpan = {span_id = 0}
        context.internal.addActive(context.internal, mockSpan)

        lu.assertEquals(#context.internal.active_spans, 1)
    end

    function TestTracingContext:testSpanStack()
        local context = TC.new("service", "instance")
        local span1 = TC.createEntrySpan(context, 'entry_op')
        local span2 = TC.createExitSpan(context, "exit_op", span1, "127.0.0.1")

        local activeSpans = context.internal.active_spans
        local finishedSpans = context.internal.finished_spans
        lu.assertEquals(#(activeSpans), 2)
        lu.assertEquals(#(finishedSpans), 0)
        lu.assertEquals(span1, activeSpans[1])
        lu.assertEquals(span2, activeSpans[2])

        Span.finish(span2)
        lu.assertNotNil(span2.end_time)
        lu.assertEquals(#(activeSpans), 1)
        lu.assertEquals(#(finishedSpans), 1)

        Span.finish(span1)
        lu.assertNotNil(span1.end_time)
        lu.assertEquals(#(activeSpans), 0)
        lu.assertEquals(#(finishedSpans), 2)

        local isSegmentFinished, segment = TC.drainAfterFinished(context)
        lu.assertEquals(span2, segment.spans[1])
        lu.assertEquals(span1, segment.spans[2])

        local segmentBuilder = Segment.transform(segment)
        local JSON = require('cjson').encode(segmentBuilder)
        lu.assertTrue(#JSON > 0)
    end

    function TestTracingContext:testNewNoOP()
        local noopContext = TC.newNoOP()

        local span1 = TC.createEntrySpan(noopContext, 'entry_op')
        local span2 = TC.createExitSpan(noopContext, "exit_op", span1, "127.0.0.1")

        lu.assertEquals(true, span1.is_noop)
        lu.assertEquals(true, span2.is_noop)
    end
-- end TestTracingContext


os.exit( lu.LuaUnit.run() )
