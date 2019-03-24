lua-laxjson
====
Lua bindings to [liblaxjson](https://github.com/andrewrk/liblaxjson)
for LuaJIT using FFI.

The library liblaxjson is a relaxed streaming JSON parser written in C.
You don't have to buffer the entire JSON string in memory before parsing it.

Usage
=====
````lua
local ffi = require "ffi"
local C = ffi.C
local laxjson = require "laxjson"

local function mydata (ctx, n)
    local v = ffi.cast("int*", ctx.userdata)
    if not n then return v[0] end
    v[0] = n
end

local laxj = laxjson.new {
    userdata = ffi.new("int[1]", 0),
    on_string = function (ctx, jtype, value, length)
        local indent = mydata(ctx)
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
        local indent = mydata(ctx)
        io.write(string.rep(" ", indent))
        print(jtype == C.LaxJsonTypeArray and "[" or "{")
        mydata(ctx, indent+1)
        return 0
    end,
    on_end = function (ctx, jtype)
        local indent = mydata(ctx)
        mydata(ctx, indent-1)
        io.write(string.rep(" ", indent-1))
        print(jtype == C.LaxJsonTypeArray and "]" or "}")
        return 0
    end
}

-- The file 'array.json' is read by 1024 bytes.
local ok, l, col, err = laxj:parse("array.json", 1024) 
if not ok then
    print("Line "..l..", column "..col..": "..err)
end

laxj:free()
````

Installation
============
To install `lua-laxjson` you need to install
[liblaxjson](https://github.com/andrewrk/liblaxjson#installation)
with shared libraries firtst.
Then you can install it by placing `laxjson.lua` to your lua library path.

Methods
=======

new
---
`syntax: laxj = laxjson.new(obj)`

Create laxjson context.

free
----
`syntax: laxj:free()`

Destroy laxjson context.

parse
-----
`syntax: ok, line, column, err = laxj:feed(json_file, size)`

Parse json file. The json file is read by `size` bytes.

Author
======
Soojin Nam jsunam@gmail.com

License
=======
Public Domain
