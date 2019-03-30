
--liblaxjson ffi binding
--Written by Soojin Nam. Public Domain.


local ffi = require "ffi"
local C = ffi.C
local NULL = ffi.null
local ffi_load = ffi.load
local ffi_str = ffi.string
local io_open = io.open
local assert = assert
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
    int (*string)(struct LaxJsonContext *,
        enum LaxJsonType type, const char *value, int length);
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
enum LaxJsonError lax_json_feed(struct LaxJsonContext *context,
    int size, const char *data);
enum LaxJsonError lax_json_eof(struct LaxJsonContext *context);
const char *lax_json_str_err(enum LaxJsonError err);
]]


-- laxjson callbacks
local function default_cb (...)
    return 0
end


-- module

local _M = {
    version = "0.3.5",
    LaxJsonTypeString = C.LaxJsonTypeString,
    LaxJsonTypeProperty = C.LaxJsonTypeProperty,
    LaxJsonTypeNumber = C.LaxJsonTypeNumber,
    LaxJsonTypeObject = C.LaxJsonTypeObject,
    LaxJsonTypeArray = C.LaxJsonTypeArray,
    LaxJsonTypeTrue = C.LaxJsonTypeTrue,
    LaxJsonTypeFalse = C.LaxJsonTypeFalse,
    LaxJsonTypeNull = C.LaxJsonTypeNull,
}


local laxjson = ffi_load "laxjson"


function _M.new (o)
    local o = o or {}
    local ctx = laxjson.lax_json_create()
    ctx['userdata'] = o.userdata or NULL
    ctx['string'] = o.on_string or default_cb
    ctx['number'] = o.on_number or default_cb
    ctx['primitive'] = o.on_primitive or default_cb
    ctx['begin'] = o.on_begin or default_cb
    ctx['end'] = o.on_end or default_cb
    return setmetatable({ ctx = ctx }, { __index = _M })
end


function _M:free ()
    if self.ctx ~= NULL then
        laxjson.lax_json_destroy(self.ctx)
        self.ctx = NULL
    end
end


local function str_err (err)
    return ffi_str(laxjson.lax_json_str_err(err))
end


function _M:lax_json_feed (size, data)
    local ctx = self.ctx
    local err = laxjson.lax_json_feed(ctx, size, data)
    if err ~= 0 then
        return false, ctx.line, ctx.column, str_err(err)
    end
    return true
end


function _M:lax_json_eof ()
    local ctx = self.ctx
    local err = laxjson.lax_json_eof(ctx)
    if err ~= 0 then
        return false, ctx.line, ctx.column, str_err(err)
    end
    return true
end


function _M:parse (fname, size)
    local err = 0
    local size = size or 2^13 -- 8K
    local ctx = self.ctx
    local f = assert(io_open(fname, "r"))
    repeat
        local buf = f:read(size)
        if not buf then break end
        err = laxjson.lax_json_feed(ctx, #buf, buf)
    until err ~= 0
    if err == 0 then
        err = laxjson.lax_json_eof(ctx)
    end
    f:close()
    local line, column = ctx.line, ctx.column
    self:free()
    return err == 0, line, column, str_err(err)
end


return _M
