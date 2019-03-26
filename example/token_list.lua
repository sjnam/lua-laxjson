local ffi = require "ffi"
local laxjson = require "laxjson"

local laxj = laxjson.new {
    on_string = function (ctx, jtype, value, length)
        local type_name
        if jtype == laxjson.LaxJsonTypeProperty then
            type_name = "property"
        else
            type_name = "string"
        end
        print(type_name..": "..ffi.string(value, length))
        return 0
    end,
    on_number = function (ctx, num)
        print("number: "..num)
        return 0
    end,
    on_primitive = function (ctx, jtype)
        local type_name
        if jtype == laxjson.LaxJsonTypeTrue then
            type_name = "true"
        elseif jtype == laxjson.LaxJsonTypeFalse then
            type_name = "false"
        else
            type_name = "null"
        end
        print("primitive: "..type_name)
        return 0
    end,
    on_begin = function (ctx, jtype)
        local type_name
        if jtype == laxjson.LaxJsonTypeArray then
            type_name = "array"
        else
            type_name = "object"
        end
        print("begin "..type_name)
        return 0
    end,
    on_end = function (ctx, jtype)
        local type_name
        if jtype == laxjson.LaxJsonTypeArray then
            type_name = "array"
        else
            type_name = "object"
        end
        print("end "..type_name)
        return 0
    end
}

-- The file 'file.json' is read by 1024 bytes.
local ok, l, col, err = laxj:parse("file.json", 1024)
if not ok then
    print("Line "..l..", column "..col..": "..err)
end
