local laxjson = require "laxjson"


local on_arr, count = false, 0

local laxj = laxjson.new {
    on_begin = function (ctx, jtype)
        if jtype == laxjson.LaxJsonTypeArray then
            on_arr = true
        elseif on_arr then
            count = count + 1
        end
        return 0
    end,
    on_end = function (ctx, jtype)
        if jtype == laxjson.LaxJsonTypeArray then
            on_arr = false
        end
        return 0
    end
}

local ok, l, col, err = laxj:parse("array.json")
if not ok then
    print("Line "..l..", column "..col..": "..err)
else
    print("# of arrayelems: "..count)
end
