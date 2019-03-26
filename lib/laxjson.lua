local ffi = require "ffi"

local C = ffi.C
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


-- on_string
local function on_string (ctx, jtype, value, length)
    return 0
end

-- on_{number, primitive, begin, end}
local function default_cb (ctx, x)
    return 0
end


-- module

local _M = {
    version = "0.3.3"
}


local laxjson = ffi_load "laxjson"


function _M.new (o)
    local o = o or {}

    local ctx = laxjson.lax_json_create()
    ctx.userdata = o.userdata
    ctx.string = o.on_string or on_string
    ctx.number = o.on_number or default_cb
    ctx.primitive = o.on_primitive or default_cb
    ctx.begin = o.on_begin or default_cb
    ctx["end"] = o.on_end or default_cb

    return setmetatable({ ctx = ctx }, { __index = _M })
end


function _M:free ()
    laxjson.lax_json_destroy(self.ctx)
end


function _M:lax_json_feed (size, data)
    local ctx = self.ctx
    local err = laxjson.lax_json_feed(ctx, size, data)
    if err ~= 0 then
        return false, ctx.line, ctx.column, ffi_str(laxjson.lax_json_str_err(err))
    end
    return true
end


function _M:lax_json_eof ()
    local ctx = self.ctx
    local err = laxjson.lax_json_eof(ctx)
    if err ~= 0 then
        return false, ctx.line, ctx.column, ffi_str(laxjson.lax_json_str_err(err))
    end
    return true
end


function _M:parse (fname, n)
    local err = 0
    local n = n or 2^13 -- 8K
    local ctx = self.ctx
    local f = assert(io_open(fname, "r"))

    repeat
        local buf = f:read(n)
        if not buf then break end
        err = laxjson.lax_json_feed(ctx, #buf, buf)
    until err ~= 0
    if err == 0 then
        err = laxjson.lax_json_eof(ctx)
    end
    f:close()
    local line, column = ctx.line, ctx.column
    laxjson.lax_json_destroy(ctx)
    if err == 0 then
        return true
    end
    return false, line, column, ffi_str(laxjson.lax_json_str_err(err))
end


return _M
