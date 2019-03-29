-- name: ctan_packages.lua
-- run "resty ctan_packages.lua"

local ffi = require "ffi"
local laxjson = require "laxjson"
local requests = require "resty.requests"

local on_arr, count = false, 0

local laxj = laxjson.new {
   on_begin = function (ctx, jtype)
      if jtype == laxjson.LaxJsonTypeArray then
         on_arr = true
      elseif on_arr then
         count = count + 1
      end
      return laxjson.LaxJsonErrorNone -- 0
   end,
   on_end = function (ctx, jtype)
      if jtype == laxjson.LaxJsonTypeArray then
         on_arr = false
      end
      return laxjson.LaxJsonErrorNone
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
   if not chunk then -- maybe eof
      ok, l, c, err = laxj:lax_json_eof()
      if not ok then
         print(l, c, err)
      end
      break
   end
   ok, l, c, err = laxj:lax_json_feed(#chunk, chunk)
   if not ok then
      print(l, c, err)
      break
   end
end

if ok then
   print("CTAN has "..count.." packages.")
end

laxj:free()
