local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_str = ffi.string
local io_open = io.open


local laxj = laxjson.new {
   fn_string = function (ctx, jtype, value, length)
      local type_name = jtype == C.LaxJsonTypeProperty and "key" or "value"
      print(type_name..": "..ffi_str(value))
      return C.LaxJsonErrorNone
   end
}

local BUFSIZE = 1024
local amt_read
local f = io_open("file.json", "r")
while true do
   local buf, rest = f:read(BUFSIZE)
   if not buf then
      break
   end
   amt_read = #buf
   local err = laxj:feed(amt_read, buf)
   if err ~= C.LaxJsonErrorNone then
      print(laxj:str_err(err))
   end
   laxj:feed(amt_read, buf)
end

local err = laxj:eof()
if err ~= C.LaxJsonErrorNone then
   print(laxj:str_err(err))
end

laxj:free()
