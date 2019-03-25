local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C

local laxj = laxjson.new {
    on_string = function (ctx, jtype, value, length)
        local type_name = jtype == C.LaxJsonTypeProperty and "property" or "string"
        print(type_name..": "..ffi.string(value, length))
        return 0
    end,
    on_number = function (ctx, num)
        print("number: "..num)
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

-- The file 'file.json' is read by 1024 bytes.
local ok, l, col, err = laxj:parse("file.json", 1024)
if not ok then
    print("Line "..l..", column "..col..": "..err)
end

laxj:free()
