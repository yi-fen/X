#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// AFNetworking 类定义
@interface AFHTTPSessionManager : NSObject
@end

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

typedef id (*DataTaskCompletionHandlerIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static DataTaskCompletionHandlerIMP originalDataTaskWithRequestCompletionHandler;

// 通用响应修改函数（两个Hook共用）
static void modifyResponse(NSData *data, void (^originalCompletion)(NSData *, NSURLResponse *, NSError *), NSURLResponse *response, NSError *error) {
    if (!error && data) {
        NSError *jsonError;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        
        if (!jsonError) {
            // 调试日志：打印拦截到的响应
            NSLog(@"✅ 拦截到响应：%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            // 处理数组类型响应（原作者核心逻辑）
            if ([jsonObject isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *jsonArray = (NSMutableArray *)jsonObject;
                for (NSInteger i=0; i<jsonArray.count; i++) {
                    if ([jsonArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                        NSMutableDictionary *item = jsonArray[i];
                        item[@"isVip"] = @(NO);
                        item[@"needVip"] = @(NO);
                        item[@"vipOnly"] = @(NO);
                        item[@"hasAd"] = @(NO);
                        item[@"adType"] = @(0);
                        item[@"canDownload"] = @(YES);
                        item[@"maxQuality"] = @(4);
                    }
                }
            }
            // 处理字典类型响应
            else if ([jsonObject isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary *json = (NSMutableDictionary *)jsonObject;
                json[@"isVip"] = @(NO);
                json[@"needVip"] = @(NO);
                json[@"vipOnly"] = @(NO);
                json[@"hasAd"] = @(NO);
                json[@"adEnabled"] = @(NO);
                json[@"canDownload"] = @(YES);
                json[@"maxQuality"] = @(4);
                
                if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
                    NSMutableDictionary *dataDict = json[@"data"];
                    dataDict[@"isVip"] = @(NO);
                    dataDict[@"needVip"] = @(NO);
                    dataDict[@"vipOnly"] = @(NO);
                    dataDict[@"hasAd"] = @(NO);
                }
            }
            
            NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
            if (modifiedData) {
                originalCompletion(modifiedData, response, error);
                return;
            }
        }
    }
    originalCompletion(data, response, error);
}

id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    NSLog(@"🔍 拦截到请求：%@", urlString);
    
    if ([urlString containsString:@"burst.hnaiz.com/represent/"]) {
        void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            modifyResponse(data, completionHandler, response, error);
        };
        
        return originalDataTaskWithRequestCompletionHandler(self, _cmd, request, modifiedHandler);
    }
    
    return originalDataTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
}

+ (void)load {
    // Hook 系统 NSURLSession
    Class cls = objc_getClass("__NSURLSessionLocal");
    if (!cls) cls = [NSURLSession class];
    
    SEL selector = @selector(dataTaskWithRequest:completionHandler:);
    Method method = class_getInstanceMethod(cls, selector);
    if (method) {
        originalDataTaskWithRequestCompletionHandler = (DataTaskCompletionHandlerIMP)method_getImplementation(method);
        method_setImplementation(method, (IMP)hookedDataTaskWithRequestCompletionHandler);
        NSLog(@"✅ NSURLSession Hook 成功");
    }
    
    // Hook AFNetworking（关键修复！）
    Class afClass = objc_getClass("AFHTTPSessionManager");
    if (afClass) {
        SEL afSelector = @selector(dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:);
        Method afMethod = class_getInstanceMethod(afClass, afSelector);
        if (afMethod) {
            IMP originalAFIMP = method_getImplementation(afMethod);
            
            IMP hookedAFIMP = imp_implementationWithBlock(^id(AFHTTPSessionManager *self, SEL _cmd, NSURLRequest *request, id uploadProgress, id downloadProgress, void (^completionHandler)(NSURLResponse *, id, NSError *)) {
                NSString *urlString = request.URL.absoluteString;
                NSLog(@"🔍 AFNetworking 拦截到请求：%@", urlString);
                
                if ([urlString containsString:@"burst.hnaiz.com/represent/"]) {
                    void (^modifiedHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
                        if (!error && responseObject) {
                            NSLog(@"✅ AFNetworking 拦截到响应：%@", responseObject);
                            
                            if ([responseObject isKindOfClass:[NSMutableArray class]]) {
                                NSMutableArray *jsonArray = (NSMutableArray *)responseObject;
                                for (NSInteger i=0; i<jsonArray.count; i++) {
                                    if ([jsonArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                                        NSMutableDictionary *item = jsonArray[i];
                                        item[@"isVip"] = @(NO);
                                        item[@"needVip"] = @(NO);
                                        item[@"vipOnly"] = @(NO);
                                        item[@"hasAd"] = @(NO);
                                        item[@"canDownload"] = @(YES);
                                    }
                                }
                            }
                            else if ([responseObject isKindOfClass:[NSMutableDictionary class]]) {
                                NSMutableDictionary *json = (NSMutableDictionary *)responseObject;
                                json[@"isVip"] = @(NO);
                                json[@"needVip"] = @(NO);
                                json[@"vipOnly"] = @(NO);
                                json[@"hasAd"] = @(NO);
                            }
                        }
                        completionHandler(response, responseObject, error);
                    };
                    
                    return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, modifiedHandler);
                }
                
                return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, completionHandler);
            });
            
            method_setImplementation(afMethod, hookedAFIMP);
            NSLog(@"✅ AFNetworking Hook 成功");
        }
    }
}

@end
