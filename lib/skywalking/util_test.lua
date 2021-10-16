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
local Util = require('skywalking.util')

TestUtil = {}
    function TestUtil.testNewID()
        local id = Util.newID()

        lu.assertNotNil(id)
    end

    function TestUtil.testTimestamp()
        local id = Util.timestamp()
        lu.assertNotNil(id)
    end

    function TestUtil.testStringSplit()
        lu.assertEquals(Util.string_split("a,b,c", ","), {"a", "b", "c"})
        lu.assertEquals(Util.string_split("a,b,", ","), {"a", "b", ""})
        lu.assertEquals(Util.string_split("a", ","), {"a"})
        lu.assertEquals(Util.string_split("", ","), {""})
    end
-- end TestUtil


os.exit( lu.LuaUnit.run() )
