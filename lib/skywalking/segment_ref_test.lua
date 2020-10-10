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
local SegmentRef = require('skywalking.segment_ref')
local cjson = require("cjson")

TestSegmentRef = {}
    -- This test is originally from ContextCarrierV2HeaderTest in the Java agent.
    function TestSegmentRef:testFromSW8Value()
        local ref = SegmentRef.fromSW8Value('1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA=')
        lu.assertNotNil(ref)
        lu.assertEquals(ref.trace_id, "3.4.5")
        lu.assertEquals(ref.segment_id, "1.2.3")
        lu.assertEquals(ref.span_id, 4)
        lu.assertEquals(ref.parent_service, "service")
        lu.assertEquals(ref.parent_service_instance, "instance")
        lu.assertEquals(ref.parent_endpoint, '/app')
        lu.assertEquals(ref.address_used_at_client, '127.0.0.1:8080')

        ref = SegmentRef.fromSW8Value('1-My40LjU=-MS')
        lu.assertNil(ref)
    end

    function TestSegmentRef:testSerialize()
        local ref = SegmentRef.new()
        ref.trace_id = "3.4.5"
        ref.segment_id = "1.2.3"
        ref.span_id = 4
        ref.parent_service = "service"
        ref.parent_service_instance = "instance"
        ref.parent_endpoint = "/app"
        ref.address_used_at_client = "127.0.0.1:8080"

        lu.assertEquals(SegmentRef.serialize(ref), '1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA=')
    end

    function TestSegmentRef:testTransform()
        local ref = SegmentRef.new()
        ref.trace_id = "3.4.5"
        ref.segment_id = "1.2.3"
        ref.span_id = 4
        ref.parent_service = "service"
        ref.parent_service_instance = "instance"
        ref.parent_endpoint = "/app"
        ref.address_used_at_client = "127.0.0.1:8080"

        local refProtocol = SegmentRef.transform(ref)
        local inJSON = cjson.encode(refProtocol)
        lu.assertTrue(string.len(inJSON) > 0)
    end
-- end TestSegmentRef


os.exit( lu.LuaUnit.run() )
