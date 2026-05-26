#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

typedef id (*DataTaskCompletionHandlerIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static DataTaskCompletionHandlerIMP originalDataTaskWithRequestCompletionHandler;

id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    
    // 完全复刻原作者的拦截规则
    if ([urlString containsString:@"burst.hnaiz.com/represent/"]) {
        void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error && data) {
                NSError *jsonError;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                
                if (!jsonError) {
                    // 处理数组类型响应（原作者脚本核心逻辑）
                    if ([jsonObject isKindOfClass:[NSMutableArray class]]) {
                        NSMutableArray *jsonArray = (NSMutableArray *)jsonObject;
                        for (NSInteger i=0; i<jsonArray.count; i++) {
                            if ([jsonArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                                NSMutableDictionary *item = jsonArray[i];
                                // 解锁所有VIP视频
                                item[@"isVip"] = @(NO);
                                item[@"needVip"] = @(NO);
                                item[@"vipOnly"] = @(NO);
                                // 关闭所有广告
                                item[@"hasAd"] = @(NO);
                                item[@"adType"] = @(0);
                                // 解锁下载权限
                                item[@"canDownload"] = @(YES);
                                // 解锁4K/1080P清晰度
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
                        
                        // 处理嵌套data结构
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
                        completionHandler(modifiedData, response, error);
                        return;
                    }
                }
            }
            completionHandler(data, response, error);
        };
        
        return originalDataTaskWithRequestCompletionHandler(self, _cmd, request, modifiedHandler);
    }
    
    return originalDataTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
}

+ (void)load {
    Class cls = objc_getClass("__NSURLSessionLocal");
    if (!cls) cls = [NSURLSession class];
    
    SEL selector = @selector(dataTaskWithRequest:completionHandler:);
    Method method = class_getInstanceMethod(cls, selector);
    if (method) {
        originalDataTaskWithRequestCompletionHandler = (DataTaskCompletionHandlerIMP)method_getImplementation(method);
        method_setImplementation(method, (IMP)hookedDataTaskWithRequestCompletionHandler);
    }
}

@end
