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

Util = {}
MAX_ID_PART2 = 1000000000
MAX_ID_PART3 = 100000
SEQ = 1

function Util:newID()
    SEQ = SEQ + 1
    return {Util.timestamp(), math.random( 0, MAX_ID_PART2), math.random( 0, MAX_ID_PART3) + SEQ}
end

-- Format a trace/segment id into an array.
-- An official ID should have three parts separated by '.' and each part of it is a number
function Util:formatID(str) 
    local parts = Util:split(str, '.')
    if #parts ~= 3 then
        return nil
    end

    parts[1] = tonumber(parts[1])
    parts[2] = tonumber(parts[2])
    parts[3] = tonumber(parts[3])

    return parts
end

-- @param id is an array with length = 3
function Util:id2String(id)
    return id[1] .. '.' .. id[2] .. '.' .. id[3]
end

-- A simulation implementation of Java's System.currentTimeMillis() by following the SkyWalking protocol.
-- Return the difference as string, measured in milliseconds, between the current time and midnight, January 1, 1970 UTC.
-- But in using os.clock(), I am not sure whether it is accurate enough.
function Util:timestamp()
    local a,b = math.modf(os.clock())
    if b==0 then 
        b='000' 
    else 
        b=tostring(b):sub(3,5) 
    end

    return os.time() * 1000 + b
end

-- Split the given string by the delimiter. The delimiter should be a literal string, such as '.', '-'
function Util:split(str, delimiter)
    local t = {}

    for substr in string.gmatch(str, "[^".. delimiter.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(t,substr)
        end
    end

    return t
end


return Util