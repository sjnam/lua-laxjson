Name
====
lua-laxjson - Lua bindings to [liblaxjson](https://github.com/andrewrk/liblaxjson)
for LuaJIT using FFI.

Status
======
This library is still experimental and under early development.

Synopsis
========
````lua
local ffi = require "ffi"
local laxjson = require "laxjson"
local C = ffi.C
local ffi_str = ffi.string
local io_open = io.open


local laxj = laxjson.new {
   fn_string = function (ctx, jtype, value, length)
      local type_name = jtype == C.LaxJsonTypeProperty and "key" or "value"
      print(type_name..": "..ffi_str(value))
      return C.LaxJsonErrorNone
   end
}

local BUFSIZE = 1024
local amt_read
local f = io_open("file.json", "r")
while true do
   local buf, rest = f:read(BUFSIZE)
   if not buf then
      break
   end
   amt_read = #buf
   local err = laxj:feed(amt_read, buf)
   if err ~= C.LaxJsonErrorNone then
      print(laxj:str_err(err))
   end
   laxj:feed(amt_read, buf)
end

local err = laxj:eof()
if err ~= C.LaxJsonErrorNone then
   print(laxj:str_err(err))
end

laxj:free()

````

Installation
============
To install `lua-laxjson` you need to install
[liblaxjson](https://github.com/andrewrk/liblaxjson#installation)
with shared libraries firtst.
Then you can install `lua-laxjson` by placing `laxjson.lua` to
your lua library path.

Methods
=======

new
---
`syntax: laxj = laxjson.new(o)`

Create cstream and dstream.

free
----
`syntax: laxj:free()`

Free cstream and dstream.

feed
----
`syntax: laxj:feed()`

feed

eof
---
`syntax: laxj:eof()`

eof

str_err
-------
`syntax: laxj:str_err(err)`

str err

Author
======
Soojin Nam jsunam@gmail.com

License
=======
Public Domain
