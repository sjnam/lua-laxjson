local ffi = require "ffi"
local C = ffi.C
local laxjson = require "laxjson"

local indent = 0

local laxj = laxjson.new {
    on_string = function (ctx, jtype, value, length)
        if jtype == C.LaxJsonTypeProperty then
            io.write(string.rep(" ", indent+1))
        end
        io.write(ffi.string(value, length))
        io.write(jtype == C.LaxJsonTypeProperty and ": " or "\n")
        return 0
    end,
    on_number = function (ctx, num)
        print(num)
        return 0
    end,
    on_primitive = function (ctx, jtype)
        local type_name = "null"
        if jtype == C.LaxJsonTypeTrue then
            type_name = "true"
        elseif jtype == C.LaxJsonTypeFalse then
            type_name = "false"
        end
        print(type_name)
        return 0
    end,
    on_begin = function (ctx, jtype)
        io.write(string.rep(" ", indent))
        print(jtype == C.LaxJsonTypeArray and "[" or "{")
        indent = indent + 1
        return 0
    end,
    on_end = function (ctx, jtype)
        indent = indent - 1
        io.write(string.rep(" ", indent))
        print(jtype == C.LaxJsonTypeArray and "]" or "}")
        return 0
    end
}

local ok, l, col, err = laxj:parse("file.json", 1024)
if not ok then
    print("Line "..l..", column "..col..": "..err)
end
