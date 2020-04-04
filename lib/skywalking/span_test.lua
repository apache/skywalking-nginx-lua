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
        local context = TC.new("service", "instance")
        lu.assertNotNil(context)

        local span1 = Span.createEntrySpan("operation_name", context, nil, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, true)
        lu.assertEquals(span1.is_exit, false)
        lu.assertEquals(span1.layer, SpanLayer.NONE)

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestSpan:testNewEntryWithContextCarrier()
        local context = TC.new("service", "instance")
        lu.assertNotNil(context)

        -- Typical header from the SkyWalking Java Agent test case
        local header = {sw8='1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA='}

        local span1 = Span.createEntrySpan("operation_name", context, nil, header)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, true)
        lu.assertEquals(span1.is_exit, false)
        lu.assertEquals(span1.layer, SpanLayer.NONE)
        local ref = span1.refs[1]
        lu.assertNotNil(ref)
        lu.assertEquals(ref.trace_id, "3.4.5")
        -- Context trace id will be overrided by the ref trace id
        lu.assertEquals(context.trace_id, "3.4.5")
        lu.assertEquals(ref.segment_id, "1.2.3")
        lu.assertEquals(ref.span_id, 4)
        lu.assertEquals(ref.parent_service, "service")
        lu.assertEquals(ref.parent_service_instance, "instance")
        lu.assertEquals(ref.address_used_at_client, '127.0.0.1:8080')
        lu.assertEquals(ref.parent_endpoint, '/app')

        lu.assertEquals(#(context.internal.active_spans), 1)
    end

    function TestSpan:testNewExit()
        local context = TC.new("service", "instance")
        lu.assertNotNil(context)

        local contextCarrier = {}
        local span1 = Span.createExitSpan("operation_name", context, nil, '127.0.0.1:80', contextCarrier)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.is_entry, false)
        lu.assertEquals(span1.is_exit, true)
        lu.assertEquals(span1.layer, SpanLayer.NONE)
        lu.assertEquals(span1.peer, '127.0.0.1:80')

        lu.assertEquals(#(context.internal.active_spans), 1)
        lu.assertNotNil(contextCarrier['sw8'])
    end

    function TestSpan:testNew()
        local context = TC.new("service", "instance")
        lu.assertNotNil(context)

        local span1 = Span.new("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.parent_span_id, -1)
        lu.assertEquals(span1.span_id, 0)
        lu.assertEquals(span1.operation_name, "operation_name")
        local span2 = Span.new("operation_name", context, span1)
        lu.assertEquals(span2.parent_span_id, 0)
        lu.assertEquals(span2.span_id, 1)
        lu.assertNil(span2.start_time)
        Span.start(span2, 123456)
        lu.assertNotNil(span2.start_time)

        -- Use new context to check again
        context = TC.new("service", "instance")
        lu.assertNotNil(context)

        span1 = Span.new("operation_name", context, nil)
        lu.assertNotNil(span1)
        lu.assertEquals(span1.parent_span_id, -1)
        lu.assertEquals(span1.span_id, 0)
    end

    function TestSpan:testProperties()
        local context = TC.new("service", "instance")

        local header = {sw8='1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA='}
        local span1 = Span.createEntrySpan("operation_name", context, nil, header)
        Span.start(span1, 1234567)
        lu.assertEquals(span1.start_time, 1234567)
        Span.finish(span1, 2222222)
        lu.assertEquals(span1.end_time, 2222222)
        Span.finishWithDuration(span1, 123)
        lu.assertEquals(span1.end_time, 1234690)

        Span.tag(span1, "key1", "value1")
        lu.assertEquals(span1.tags[1].value, 'value1')

        lu.assertEquals(#span1.refs, 1)
        lu.assertEquals(span1.refs[1].address_used_at_client, '127.0.0.1:8080')
    end

    function TestSpan:testTransform()
        local context = TC.new("service", "instance")

        local header = {sw8='1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA='}
        local span1 = Span.createEntrySpan("operation_name", context, nil, header)
        Span.start(span1, 1234567)
        Span.finish(span1, 2222222)
        Span.tag(span1, "key", "value")
        Span.log(span1, 123, {logkey="logvalue", logkey1="logvalue2"})

        local spanBuilder = Span.transform(span1)
        lu.assertEquals(#spanBuilder.refs, 1)
        lu.assertNil(spanBuilder.spanLayer)
        lu.assertEquals(spanBuilder.spanType, "Entry")
        lu.assertEquals(#spanBuilder.logs, 1)
        lu.assertEquals(spanBuilder.logs[1].data["logkey"], "logvalue")
        lu.assertEquals(spanBuilder.logs[1].data["logkey1"], "logvalue2")
    end
-- end TestSpan


os.exit( lu.LuaUnit.run() )
