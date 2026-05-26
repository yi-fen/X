#ifndef QUICKJS_H
#define QUICKJS_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef struct JSRuntime JSRuntime;
typedef struct JSContext JSContext;
typedef uint64_t JSValue;

JSRuntime *JS_NewRuntime(void);
JSContext *JS_NewContext(JSRuntime *rt);
void JS_FreeContext(JSContext *ctx);
void JS_FreeRuntime(JSRuntime *rt);
JSValue JS_Eval(JSContext *ctx, const char *code, size_t len, const char *filename, int flags);
void JS_FreeValue(JSContext *ctx, JSValue v);
int JS_IsError(JSContext *ctx, JSValue v);
const char *JS_ToCString(JSContext *ctx, JSValue v);

#define JS_UNDEFINED 0
#define JS_VALUE_GET_INT(v) ((int)(v))

#endif
