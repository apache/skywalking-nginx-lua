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

local idGen = require('id_generator')

TracingContext = {
    span_id_seq = 0,
    trace_id,
    segment_id,
    -- Linked Lists
    finished_spans = nil,
}

function TracingContext:new(o)
    o = o or {} 
    setmetatable(o, self)

    o.trace_id = idGen.newID();
    o.segment_id = o.trace_id
    return o
end

function TracingContext:createEntrySpan(operationName)
end

return TracingContext