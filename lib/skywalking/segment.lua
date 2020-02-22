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

-- Segment represents a finished tracing context
-- Including all information to send to the SkyWalking OAP server.

local cjson = require("cjson")

local Segment = {
    trace_id,
    segment_id,
    service_id,
    service_inst_id,
    spans,
}

-- Due to nesting relationship inside Segment/Span/TracingContext at the runtime,
-- SegmentProtocol is created to prepare JSON format serialization.
-- Following SkyWalking official trace protocol v2
-- https://github.com/apache/skywalking-data-collect-protocol/blob/master/language-agent-v2/trace.proto
local SegmentProtocol = {
    serviceId,
    serviceInstanceId,
    spans,
}

function Segment:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    return o
end

-- Transform the segment object to the 
function Segment:transform()
    return cjson.encode(self)
end

return Segment