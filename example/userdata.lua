local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local io_open = io.open
local LaxJsonTypeString = C.LaxJsonTypeString
local LaxJsonTypeProperty = C.LaxJsonTypeProperty
local LaxJsonTypeNumber = C.LaxJsonTypeNumber
local LaxJsonTypeObject = C.LaxJsonTypeObject
local LaxJsonTypeArray = C.LaxJsonTypeArray
local LaxJsonTypeTrue = C.LaxJsonTypeTrue
local LaxJsonTypeFalse = C.LaxJsonTypeFalse
local LaxJsonTypeNull = C.LaxJsonTypeNull

ffi.cdef[[
typedef struct {
     char *id;
     uint8_t menu, count;
} mydata_t;
]]


local function mydata (data)
    return ffi_cast("mydata_t*", data)
end


local function on_end (ctx, ltype)
    if ltype == LaxJsonTypeArray then
        local data = mydata(ctx.userdata)
        data.menu = 0
        print("end of menuitem")
    end
    return 0
end


local laxj = laxjson.new {
    userdata = ffi_new("mydata_t[1]"),
    on_string = function (ctx, ltype, value, length)
        if ltype == LaxJsonTypeProperty then
            if ffi_str(value) == "id" then
                print("id found")
            end
        end
        return 0
    end,

    on_begin = function (ctx, ltype)
        local data = mydata(ctx.userdata)
        if ltype == LaxJsonTypeArray then
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

local amt_read
local f = io_open("file.json", "r")
while true do
    local buf = f:read(32)
    if not buf then break end
    amt_read = #buf
    local ok, l, col, err = laxj:feed(amt_read, buf)
    if not ok then
        print(string.format("Line %d, column %d: %s", l, col, err))
        laxj:free()
        return
    end
end

local ok, l, col, err = laxj:eof()
if not ok then
    print(string.format("Line %d, column %d: %s", l, col, err))
end

print("# of menuitem: "..mydata(laxj.userdata).count)


laxj:free()
