local ffi = require "ffi"
local laxjson = require "laxjson"

local indent = 0

local laxj = laxjson.new {
    on_string = function (ctx, jtype, value, length)
        if jtype == laxjson.LaxJsonTypeProperty then
            io.write(string.rep(" ", indent+1))
        end
        io.write(ffi.string(value, length))
        io.write(jtype == laxjson.LaxJsonTypeProperty and ": " or "\n")
        return laxjson.LaxJsonErrorNone
    end,
    on_number = function (ctx, num)
        print(num)
        return laxjson.LaxJsonErrorNone
    end,
    on_primitive = function (ctx, jtype)
        local type_name = "null"
        if jtype == laxjson.LaxJsonTypeTrue then
            type_name = "true"
        elseif jtype == laxjson.LaxJsonTypeFalse then
            type_name = "false"
        end
        print(type_name)
        return laxjson.LaxJsonErrorNone
    end,
    on_begin = function (ctx, jtype)
        io.write(string.rep(" ", indent))
        print(jtype == laxjson.LaxJsonTypeArray and "[" or "{")
        indent = indent + 1
        return laxjson.LaxJsonErrorNone
    end,
    on_end = function (ctx, jtype)
        indent = indent - 1
        io.write(string.rep(" ", indent))
        print(jtype == laxjson.LaxJsonTypeArray and "]" or "}")
        return laxjson.LaxJsonErrorNone
    end
}

local ok, l, col, err = laxj:parse("file.json", 1024)
if not ok then
    print("Line "..l..", column "..col..": "..err)
end
