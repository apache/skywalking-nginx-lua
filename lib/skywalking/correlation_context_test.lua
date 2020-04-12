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
local correlationContext = require('correlation_context')
local TC = require('tracing_context')

TestCorelationContext = {}
    function TestCorelationContext:testFromSW8Value()
        -- simple analyze
        local context = correlationContext.fromSW8Value('dGVzdDE=:dDE=,dGVzdDI=:dDI=')
        lu.assertNotNil(context)
        lu.assertEquals(context["test1"], "t1")
        lu.assertEquals(context["test2"], "t2")

        -- analyze with empty value
        context = correlationContext.fromSW8Value('dGVzdDE=:')
        lu.assertNotNil(context)
        lu.assertEquals(context["test1"], "")

        -- analyze with empty header
        context = correlationContext.fromSW8Value('')
        lu.assertNotNil(context)
        lu.assertNotNil(#context == 0)
    end

    function TestCorelationContext:testSerialize()
        -- serialize empty correlation
        local context = correlationContext.fromSW8Value('')
        local encode_context = correlationContext.serialize(context)
        lu.assertNotNil(encode_context)
        lu.assertEquals(encode_context, "")

        -- serialize with multiple value
        context = correlationContext.fromSW8Value('')
        correlationContext.put(context, "test1", "t1")
        correlationContext.put(context, "test2", "t2")
        encode_context = correlationContext.serialize(context)
        lu.assertNotNil(encode_context)
        context = correlationContext.fromSW8Value(encode_context)
        lu.assertNotNil(context)
        lu.assertEquals(context["test1"], "t1")
        lu.assertEquals(context["test2"], "t2")

        -- serialize with empty value
        context = correlationContext.fromSW8Value('')
        correlationContext.put(context, "test1", "")
        encode_context = correlationContext.serialize(context)
        lu.assertNotNil(encode_context)
        lu.assertEquals(encode_context, "dGVzdDE=:")
    end

    function TestCorelationContext:testPut()
        -- put with empty key and value
        local context = correlationContext.fromSW8Value('')
        correlationContext.put(context, nil, nil)
        lu.assertEquals(correlationContext.serialize(context), '')

        -- put nil to remove key
        correlationContext.put(context, "test1", "t1")
        correlationContext.put(context, "test1", nil)
        lu.assertEquals(correlationContext.serialize(context), '')

        -- overflow put
        correlationContext.put(context, "test1", "t1")
        correlationContext.put(context, "test2", "t2")
        correlationContext.put(context, "test3", "t3")
        correlationContext.put(context, "test4", "t4")
        local encode_context = correlationContext.serialize(context)
        lu.assertNotNil(encode_context)
        local context = correlationContext.fromSW8Value(encode_context)
        lu.assertEquals(context["test1"], "t1")
        lu.assertEquals(context["test2"], "t2")
        lu.assertEquals(context["test3"], "t3")
    end

    function TestCorelationContext:testTracingContext()
        -- transform data
        local context = TC.new("service", "instance")
        local header = {}
        header["sw8-correlation"] = 'dGVzdDI=:dDI=,dGVzdDE=:dDE=,dGVzdDM=:dDM='
        TC.createEntrySpan(context, 'operation_name', nil, header)
        lu.assertNotNil(context.correlation)
        local contextCarrier = {}
        TC.createExitSpan(context, 'operation_name', nil, 'peer', contextCarrier)
        lu.assertNotNil(contextCarrier['sw8-correlation'])
        local correlation = correlationContext.fromSW8Value(contextCarrier['sw8-correlation'])
        lu.assertEquals(correlation["test1"], "t1")
        lu.assertEquals(correlation["test2"], "t2")

        -- transform data with adding data
        TC.createExitSpan(context, 'operation_name', nil, 'peer', contextCarrier, {
            test3 = "t3"
        })
        lu.assertNotNil(contextCarrier['sw8-correlation'])
        correlation = correlationContext.fromSW8Value(contextCarrier['sw8-correlation'])
        lu.assertEquals(correlation["test1"], "t1")
        lu.assertEquals(correlation["test2"], "t2")
        lu.assertEquals(correlation["test3"], "t3")
    end

-- end TestTracingContext


os.exit( lu.LuaUnit.run() )
