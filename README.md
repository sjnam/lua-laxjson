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
