local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local LaxJsonTypeProperty = C.LaxJsonTypeProperty
local LaxJsonTypeArray = C.LaxJsonTypeArray


ffi.cdef[[
typedef struct {
     char *id;
     uint8_t menu, count;
} mydata_t;
]]


local function mydata (data)
    return ffi_cast("mydata_t*", data)
end


local function on_end (ctx, jtype)
    if jtype == LaxJsonTypeArray then
        local data = mydata(ctx.userdata)
        data.menu = 0
        print("end of menuitem")
    end
    return 0
end


local laxj = laxjson.new {
    userdata = ffi_new("mydata_t[1]"),
    on_string = function (ctx, jtype, value, length)
        if jtype == LaxJsonTypeProperty then
            if ffi_str(value) == "id" then
                print("id found")
            end
        end
        return 0
    end,

    on_begin = function (ctx, jtype)
        local data = mydata(ctx.userdata)
        if jtype == LaxJsonTypeArray then
            data.menu = 1
            data.count = 0
        else
            if data.menu == 1 then
                data.count = data.count + 1
            end
        end
        return 0
    end
}

laxj:set_on_end(on_end)


local ok, l, col, err = laxj:parse("file.json")
if not ok then
    print("Line "..l..", column "..col..": "..err)
end

print("# of menuitem: "..mydata(laxj.userdata).count)

laxj:free()
