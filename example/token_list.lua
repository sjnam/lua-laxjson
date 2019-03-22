local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_str = ffi.string
local io_open = io.open

-- If you don't declare callback functions, default callbacks are used.
-- local laxj = laxjson.new()
local laxj = laxjson.new {
   fn_string = function (ctx, ltype, value, length)
      local type_name = ltype == C.LaxJsonTypeProperty and "property" or "string"
      print(type_name..": "..ffi_str(value))
      return 0
   end,
   fn_number = function (ctx, x)
      print(x)
      return 0
   end,
   fn_primitive = function (ctx, ltype)
      local type_name
      if ltype == C.LaxJsonTypeTrue then
         type_name = "true"
      elseif ltype == C.LaxJsonTypeFalse then
         type_name = "false"
      else
         type_name = "null"
      end
      print("primitive: "..type_name)
      return 0
   end,
   fn_begin = function (ctx, ltype)
      local type_name = ltype == C.LaxJsonTypeArray and "array" or "object"
      print("begin "..type_name)
      return 0
   end,
   fn_end = function (ctx, ltype)
      local type_name = ltype == C.LaxJsonTypeArray and "array" or "object"
      print("end "..type_name)
      return 0
   end
}

local amt_read
local f = io_open("file.json", "r")
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

laxj:free()
