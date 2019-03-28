lua-laxjson
====
Lua binding to [liblaxjson](https://github.com/andrewrk/liblaxjson)
for LuaJIT using FFI.

The library liblaxjson is a relaxed streaming JSON parser written in C.
You don't have to buffer the entire JSON string in memory before parsing it.

Usage
=====

- Parsing a file
````lua
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
````

- Parsing a stream
````lua
local ffi = require "ffi"
local laxjson = require "laxjson"
local requests = require "resty.requests"

local indent = 0

local laxj = laxjson.new {
    on_string = function (ctx, jtype, value, length)
        if jtype == laxjson.LaxJsonTypeProperty then
            io.write(string.rep(" ", indent+1))
        end
        io.write(ffi.string(value, length))
        io.write(jtype == laxjson.LaxJsonTypeProperty and ": " or "\n")
        return 0
    end,
    on_number = function (ctx, num)
        print(num)
        return 0
    end,
    on_primitive = function (ctx, jtype)
        local type_name = "null"
        if jtype == laxjson.LaxJsonTypeTrue then
            type_name = "true"
        elseif jtype == laxjson.LaxJsonTypeFalse then
            type_name = "false"
        end
        print(type_name)
        return 0
    end,
    on_begin = function (ctx, jtype)
        io.write(string.rep(" ", indent))
        print(jtype == laxjson.LaxJsonTypeArray and "[" or "{")
        indent = indent + 1
        return 0
    end,
    on_end = function (ctx, jtype)
        indent = indent - 1
        io.write(string.rep(" ", indent))
        print(jtype == laxjson.LaxJsonTypeArray and "]" or "}")
        return 0
    end
}

local url = "https://ctan.org/json/2.0/packages"
local r, err = requests.get(url)
if not r then
    print(err)
    return
end

local chunk
local ok, l, c,  err
while true do
    chunk, err = r:iter_content(2^13) -- reads by 8K bytes
    if not chunk then
        print(err)
        return
    end
    ok, l, c, err = laxj:lax_json_feed(#chunk, chunk)
    if not ok then
        print(l, c, err)
        break
    end
end

if ok then
    ok, l, c, err = laxj:lax_json_eof()
    if not ok then
        print(l, c, err)
    end
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

feed
----
`syntax: ok, line, column, err = laxj:feed(size, buf)`

Feed string to parse by `size` bytes.

eof
---
`syntax: ok, line, column, err = laxj:eof()`

Check EOF.

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
