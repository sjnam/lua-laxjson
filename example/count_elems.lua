local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local LaxJsonTypeArray = C.LaxJsonTypeArray
local LaxJsonTypeProperty = C.LaxJsonTypeProperty


ffi.cdef[[
typedef struct {
    char id[16];
    uint8_t array, count;
} mydata_t;
]]


local userdata = ffi_new("mydata_t[1]")

local function mydata (ctx)
    return ffi_cast("mydata_t*", ctx.userdata)
end


local laxj = laxjson.new {
    userdata = userdata,
    on_begin = function (ctx, jtype)
        local data = mydata(ctx)
        if jtype == LaxJsonTypeArray then
            mydata(ctx).array = 1
        elseif data.array == 1 then
            mydata(ctx).count = data.count + 1
        end
        return 0
    end,
    on_end = function (ctx, jtype)
        if jtype == LaxJsonTypeArray then
            mydata(ctx).array = 0
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

laxj:free()
