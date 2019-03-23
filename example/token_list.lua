local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_str = ffi.string

-- If you don't declare callback functions, default callbacks are used.
-- local laxj = laxjson.new()
local laxj = laxjson.new {
   on_string = function (ctx, jtype, value, length)
      local type_name = jtype == C.LaxJsonTypeProperty and "property" or "string"
      print(type_name..": "..ffi_str(value, length))
      return 0
   end,
   on_number = function (ctx, x)
      print(x)
      return 0
   end,
   on_primitive = function (ctx, jtype)
      local type_name
      if jtype == C.LaxJsonTypeTrue then
         type_name = "true"
      elseif jtype == C.LaxJsonTypeFalse then
         type_name = "false"
      else
         type_name = "null"
      end
      print("primitive: "..type_name)
      return 0
   end,
   on_begin = function (ctx, jtype)
      local type_name = jtype == C.LaxJsonTypeArray and "array" or "object"
      print("begin "..type_name)
      return 0
   end,
   on_end = function (ctx, jtype)
      local type_name = jtype == C.LaxJsonTypeArray and "array" or "object"
      print("end "..type_name)
      return 0
   end
}

local ok, l, col, err = laxj:parse("file.json")
if not ok then
    print("Line "..l..", column "..col..": "..err)
end

laxj:free()
