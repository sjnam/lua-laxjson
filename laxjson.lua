local ffi = require "ffi"

local C = ffi.C
local ffi_load = ffi.load
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


local laxjson = ffi_load "laxjson"

local _M = {
    version = "0.0.1"
}

local mt = { __index = _M }


function _M.new ()
    return setmetatable({ ctx = laxjson.lax_json_create() }, mt);
end


function _M:free ()
    laxjson.lax_json_destroy(self.ctx);
end


return _M
