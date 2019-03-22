local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local io_open = io.open

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
    if ltype == C.LaxJsonTypeArray then
        local data = mydata(ctx.userdata)
        data.menu = 0
        print("end of menuitem")
    end
    return 0
end


local laxj = laxjson.new {
    userdata = ffi.new("mydata_t[1]"),
    on_string = function (ctx, ltype, value, length)
        if ltype == C.LaxJsonTypeProperty then
            if ffi_str(value) == "id" then
                print("id found")
            end
        end
        return 0
    end,

    on_begin = function (ctx, ltype)
        local data = mydata(ctx.userdata)
        if ltype == C.LaxJsonTypeArray then
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
local f = io_open("menu.json", "r")
while true do
    local buf = f:read(32)
    if not buf then break end
    amt_read = #buf
    local err = laxj:feed(amt_read, buf)
    if err ~= C.LaxJsonErrorNone then
        print(string.format("Line %d, column %d: %s\n",
                            laxj.line, laxj.column, laxj:str_err(err)))
        laxj:free()
        return
    end
end

local err = laxj:eof()
if err ~= C.LaxJsonErrorNone then
    print(string.format("Line %d, column %d: %s\n",
                        laxj.line, laxj.column, laxj:str_err(err)))
end

print("# of menuitem: "..mydata(laxj.userdata).count)


laxj:free()
