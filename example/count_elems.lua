local ffi = require "ffi"
local C = ffi.C
local laxjson = require "laxjson"


ffi.cdef[[
typedef struct {
    uint8_t on_arr, count;
} mydata_t;
]]


local userdata = ffi.new("mydata_t[1]")

local function mydata (ctx)
    return ffi.cast("mydata_t*", ctx.userdata)
end


local laxj = laxjson.new {
    userdata = userdata,
    on_begin = function (ctx, jtype)
        local data = mydata(ctx)
        if jtype == C.LaxJsonTypeArray then
            mydata(ctx).on_arr = 1
        elseif data.on_arr == 1 then
            mydata(ctx).count = data.count + 1
        end
        return 0
    end,
    on_end = function (ctx, jtype)
        if jtype == C.LaxJsonTypeArray then
            mydata(ctx).on_arr = 0
        end
        return 0
    end
}

local ok, l, col, err = laxj:parse("array.json")
if not ok then
    print("Line "..l..", column "..col..": "..err)
else
    print("# of arrayelems: "..userdata[0].count)
end
