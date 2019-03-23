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
     uint8_t id, menu, count;
} mydata_t;
]]


local function mydata (ctx)
    return ffi_cast("mydata_t*", ctx.userdata)
end


local laxj = laxjson.new {
    userdata = ffi_new("mydata_t[1]"),
    on_string = function (ctx, jtype, value, length)
        local data = mydata(ctx)
        if jtype == LaxJsonTypeProperty then
            if ffi_str(value) == "id" then
                data.id = 1
            end
        else
            if data.id == 1 then
                print("id: "..ffi_str(value, length))
                data.id = 0
            end
        end
        return 0
    end,
    on_begin = function (ctx, jtype)
        local data = mydata(ctx)
        if jtype == LaxJsonTypeArray then
            data.menu = 1
            data.count = 0
        else
            if data.menu == 1 then
                data.count = data.count + 1
            end
        end
        return 0
    end,
    on_end = function (ctx, jtype)
        if jtype == LaxJsonTypeArray then
            local data = mydata(ctx)
            data.menu = 0
        end
        return 0
    end
}

local ok, l, col, err = laxj:parse("file.json")
if not ok then
    print("Line "..l..", column "..col..": "..err)
end

print("# of menuitem: "..mydata(laxj.ctx).count)

laxj:free()
