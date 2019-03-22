local ffi = require "ffi"

local C = ffi.C
local ffi_load = ffi.load
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof
local NULL = ffi.null
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

/* All callbacks must be provided. Return nonzero to abort the ongoing feed operation. */
struct LaxJsonContext {
    void *userdata;
    /* type can be property or string */
    int (*string)(struct LaxJsonContext *, enum LaxJsonType type, const char *value, int length);
    /* type is always number */
    int (*number)(struct LaxJsonContext *, double x);
    /* type can be true, false, or null */
    int (*primitive)(struct LaxJsonContext *, enum LaxJsonType type);
    /* type can be array or object */
    int (*begin)(struct LaxJsonContext *, enum LaxJsonType type);
    /* type can be array or object */
    int (*end)(struct LaxJsonContext *, enum LaxJsonType type);

    int line;
    int column;

    int max_state_stack_size;
    int max_value_buffer_size;

    /* private members */
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


local void_t = ffi_typeof("void *")
local string_t = ffi_typeof("int (*)(struct LaxJsonContext *, enum LaxJsonType, const char *, int)")
local number_t = ffi_typeof("int (*)(struct LaxJsonContext *, double)")
local other_t = ffi_typeof("int (*)(struct LaxJsonContext *, enum LaxJsonType)")


local function on_string (ctx, jtype, value, length)
    return 0
end


local function on_number (ctx, x)
    return 0
end


local function on_primitive (ctx, jtype)
    return 0
end


local function on_begin (ctx, jtype)
    return 0
end


local function on_end (ctx, jtype)
    return 0
end


local laxjson = ffi_load "laxjson"


local _M = {
    version = "0.2.8"
}


local mt = { __index = _M }


function _M.new (o)
    local o = o or {}

    local ctx = laxjson.lax_json_create()
    ctx.userdata = ffi_cast(void_t, o.userdata or NULL)
    ctx.string = ffi_cast(string_t, o.on_string or on_string)
    ctx.number = ffi_cast(number_t, o.on_number or on_number)
    ctx.primitive = ffi_cast(other_t, o.on_primitive or on_primitive)
    ctx.begin = ffi_cast(other_t, o.on_begin or on_begin)
    ctx["end"] = ffi_cast(other_t, o.on_end or on_end)

    return setmetatable({ ctx = ctx, userdata = ctx.userdata }, mt)
end


function _M:set_userdata (data)
    self.ctx.userdata = ffi_cast("void *", data)
end


function _M:set_on_string (fn)
    self.ctx.string = ffi_cast(string_t, fn)
end


function _M:set_on_number (fn)
    self.ctx.number = ffi_cast(number_t, fn)
end


function _M:set_on_primitive (fn)
    self.ctx.primitive = ffi_cast(other_t, fn)
end


function _M:set_on_begin (fn)
    self.ctx.begin = ffi_cast(other_t, fn)
end


function _M:set_on_end (fn)
    self.ctx["end"] = ffi_cast(other_t, fn)
end


function _M:feed (amt_read, buf)
    local err = laxjson.lax_json_feed(self.ctx, amt_read, buf)
    self.line = self.ctx.line
    self.column = self.ctx.column
    return err
end


function _M:eof ()
    local err = laxjson.lax_json_eof(self.ctx)
    self.line = self.ctx.line
    self.column = self.ctx.column
    return err
end


function _M:str_err (err)
    return ffi_str(laxjson.lax_json_str_err(err))
end


function _M:free ()
    laxjson.lax_json_destroy(self.ctx);
end


return _M
