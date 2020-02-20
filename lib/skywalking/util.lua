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


return Util