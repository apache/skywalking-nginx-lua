local lu = require('luaunit')

local function range(start, stop)
    -- return list of { start ... stop }
    local i 
    local ret = {}
    i=start
    while i <= stop do
        table.insert(ret, i)
        i = i + 1
    end
    return ret
end


TestListCompare = {}

    function TestListCompare:test1()
        local A = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 122121, 121212, 122121 } 
        local B = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 121221, 121212, 122121 }
        lu.assertEquals( A, B )
    end
-- end TestListCompare

--[[
TestDictCompare = {}
    function XTestDictCompare:test1()
        lu.assertEquals( {one=1,two=2, three=3}, {one=1,two=1, three=3} )
    end
    function XTestDictCompare:test2()
        lu.assertEquals( {one=1,two=2, three=3, four=4, five=5}, {one=1,two=1, three=3, four=4, five=5} )
    end
-- end TestDictCompare
]]


os.exit( lu.LuaUnit.run() )
