local ffi = require "ffi"

local C = ffi.C
local ffi_load = ffi.load
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof
local print = print
local setmetatable = setmetatable


ffi.cdef[[
enum LaxJsonType {
    LaxJsonTypeString,
    LaxJsonTypeProperty,
    LaxJsonTypeNumber,
    LaxJsonTypeObject,
    LaxJsonTypeArray,
    LaxJsonTypeTrue,
    LaxJsonTypeFalse,
    LaxJsonTypeNull
};

enum LaxJsonState {
    LaxJsonStateValue,
    LaxJsonStateObject,
    LaxJsonStateArray,
    LaxJsonStateString,
    LaxJsonStateStringEscape,
    LaxJsonStateUnicodeEscape,
    LaxJsonStateBareProp,
    LaxJsonStateCommentBegin,
    LaxJsonStateCommentLine,
    LaxJsonStateCommentMultiLine,
    LaxJsonStateCommentMultiLineStar,
    LaxJsonStateExpect,
    LaxJsonStateEnd,
    LaxJsonStateColon,
    LaxJsonStateNumber,
    LaxJsonStateNumberDecimal,
    LaxJsonStateNumberExponent,
    LaxJsonStateNumberExponentSign
};

enum LaxJsonError {
    LaxJsonErrorNone,
    LaxJsonErrorUnexpectedChar,
    LaxJsonErrorExpectedEof,
    LaxJsonErrorExceededMaxStack,
    LaxJsonErrorNoMem,
    LaxJsonErrorExceededMaxValueSize,
    LaxJsonErrorInvalidHexDigit,
    LaxJsonErrorInvalidUnicodePoint,
    LaxJsonErrorExpectedColon,
    LaxJsonErrorUnexpectedEof,
    LaxJsonErrorAborted
};

struct LaxJsonContext {
    void *userdata;
    int (*string)(struct LaxJsonContext *, enum LaxJsonType type, const char *value, int length);
    int (*number)(struct LaxJsonContext *, double x);
    int (*primitive)(struct LaxJsonContext *, enum LaxJsonType type);
    int (*begin)(struct LaxJsonContext *, enum LaxJsonType type);
    int (*end)(struct LaxJsonContext *, enum LaxJsonType type);
    int line;
    int column;
    int max_state_stack_size;
    int max_value_buffer_size;
    enum LaxJsonState state;
    enum LaxJsonState *state_stack;
    int state_stack_index;
    int state_stack_size;
    char *value_buffer;
    int value_buffer_index;
    int value_buffer_size;
    unsigned int unicode_point;
    unsigned int unicode_digit_index;
    char *expected;
    char delim;
    enum LaxJsonType string_type;
};

struct LaxJsonContext *lax_json_create(void);
void lax_json_destroy(struct LaxJsonContext *context);
enum LaxJsonError lax_json_feed(struct LaxJsonContext *context, int size, const char *data);
enum LaxJsonError lax_json_eof(struct LaxJsonContext *context);
const char *lax_json_str_err(enum LaxJsonError err);
]]


local string_t = ffi_typeof("int (*)(struct LaxJsonContext *, enum LaxJsonType, const char *, int)")
local number_t = ffi_typeof("int (*)(struct LaxJsonContext *, double)")
local other_t = ffi_typeof("int (*)(struct LaxJsonContext *, enum LaxJsonType)")


local function default_string (ctx, jtype, value, length)
   local type_name = jtype == C.LaxJsonTypeProperty and "property" or "string"
   print(type_name..": "..ffi_str(value))
   return C.LaxJsonErrorNone
end


local function default_number (ctx, x)
   print(x)
   return C.LaxJsonErrorNone
end


local function default_primitive (ctx, jtype)
   local type_name
   if jtype == C.LaxJsonTypeTrue then
      type_name = "true"
   elseif jtype == C.LaxJsonTypeFalse then
      type_name = "false"
   else
      type_name = "null"
   end
   print("primitive: "..type_name)
   return C.LaxJsonErrorNone
end


local function default_begin (ctx, jtype)
   local type_name = jtype == C.LaxJsonTypeArray and "array" or "object"
   print("begin "..type_name)
   return C.LaxJsonErrorNone
end


local function default_end (ctx, jtype)
   local type_name = jtype == C.LaxJsonTypeArray and "array" or "object"
   print("end "..type_name)
   return C.LaxJsonErrorNone
end


local laxjson = ffi_load "laxjson"


local _M = {
   version = "0.0.1"
}


local mt = { __index = _M }


function _M.new (o)
   local o = o or {}
   local ctx = laxjson.lax_json_create()
   ctx[0].string = ffi_cast(string_t, o.fn_string or default_string)
   ctx[0].number = ffi_cast(number_t, o.fn_number or default_number)
   ctx[0].primitive = ffi_cast(other_t, o.fn_primitive or default_primitive)
   ctx[0].begin = ffi_cast(other_t, o.fn_begin or default_begin)
   ctx[0]["end"] = ffi_cast(other_t, o.fn_end or default_end)

   return setmetatable({ ctx = ctx }, mt)
end


function _M:set_fn_string (fn)
   self.ctx[0].string = ffi_cast(string_t, fn)
end


function _M:set_fn_number (fn)
   self.ctx[0].number = ffi_cast(number_t, fn)
end


function _M:set_fn_primitive (fn)
   self.ctx[0].primitive = ffi_cast(other_t, fn)
end


function _M:set_fn_begin (fn)
   self.ctx[0].begin = ffi_cast(other_t, fn)
end


function _M:set_fn_end (fn)
   self.ctx[0]["end"] = ffi_cast(other_t, fn)
end


function _M:feed (amt_read, buf)
   local err = laxjson.lax_json_feed(self.ctx, amt_read, buf)
   self.line = self.ctx[0].line
   self.column = self.ctx[0].column
   return err
end


function _M:eof ()
   local err = laxjson.lax_json_eof(self.ctx)
   self.line = self.ctx[0].line
   self.column = self.ctx[0].column
   return err
end


function _M:str_err (err)
   return ffi_str(laxjson.lax_json_str_err(err))
end


function _M:free ()
   laxjson.lax_json_destroy(self.ctx);
end


return _M
