#include "quickjs.h"

// 极简适配版，只保留Theos编译必需接口
JSRuntime *JS_NewRuntime(void) { return (JSRuntime *)1; }
JSContext *JS_NewContext(JSRuntime *rt) { return (JSContext *)1; }
void JS_FreeContext(JSContext *ctx) {}
void JS_FreeRuntime(JSRuntime *rt) {}
void JS_FreeValue(JSContext *ctx, JSValue v) {}
int JS_IsError(JSContext *ctx, JSValue v) { return 0; }
const char *JS_ToCString(JSContext *ctx, JSValue v) { return ""; }

JSValue JS_Eval(JSContext *ctx, const char *code, size_t len, const char *filename, int flags)
{
    return 0;
}
