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

local spanLayer = require("span_layer")
local Context = require("tracing_context")
local Util = require('util')

Span = {
    span_id,
    parent_span_id,
    operation_name,
    tags,
    logs,
    layer = spanLayer.NONE,
    isEntry = false,
    isExit = false,
    peer,
    start_time,
    end_time,
    error_occurred = false,
}

-- Create an entry span, represent the HTTP incoming request.
function Span:createEntrySpan(operationName, context, parent)
    local span = self:new(operationName, context, parent)
    span.isEntry = true

    return span
end

-- Create a default span.
-- Usually, this method wouldn't be called by outside directly.
-- Read newEntrySpan, newExitSpan and newLocalSpan for more details
function Span:new(operationName, context, parent)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.operation_name = operationName
    o.span_id = context.internal:nextSpanID()
    if parent == nil then
        -- As the root span, the parent span id is -1
        o.parent_span_id = -1
    else
        o.parent_span_id = parent.span_id
    end 

    context.internal:addActive(o)
    o.start_time = Util.timestamp()

    return o
end

return Span
