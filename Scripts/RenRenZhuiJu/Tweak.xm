#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

// 修复：显式定义函数指针类型，解决参数数量不匹配错误
typedef id (*DataTaskCompletionHandlerIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static DataTaskCompletionHandlerIMP originalDataTaskWithRequestCompletionHandler;

id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    
    // 覆盖人人追剧所有主流版本的会员接口
    NSArray *targetAPIs = @[
        @"/api/v1/user/info",
        @"/api/v2/user/vip",
        @"/api/user/vipStatus",
        @"/api/vip/info",
        @"/api/app/config",
        @"/api/user/getInfo",
        @"/api/v3/user/profile"
    ];
    
    for (NSString *api in targetAPIs) {
        if ([urlString containsString:api]) {
            void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (!error && data) {
                    NSError *jsonError;
                    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                    if (!jsonError && json) {
                        // 通用会员字段（适配99%版本）
                        json[@"vip"] = @(YES);
                        json[@"isVip"] = @(YES);
                        json[@"vipType"] = @(3); // 3=永久会员
                        json[@"vipLevel"] = @(99);
                        json[@"expireTime"] = @(4070880000); // 2099-12-31
                        json[@"expireDate"] = @"2099-12-31";
                        json[@"isForeverVip"] = @(YES);
                        json[@"adEnabled"] = @(NO);
                        json[@"showAd"] = @(NO);
                        json[@"canWatchVip"] = @(YES);
                        json[@"canDownload"] = @(YES);
                        json[@"adFree"] = @(YES);
                        
                        // 处理嵌套data结构（最常见的返回格式）
                        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
                            NSMutableDictionary *dataDict = json[@"data"];
                            dataDict[@"vip"] = @(YES);
                            dataDict[@"isVip"] = @(YES);
                            dataDict[@"vipType"] = @(3);
                            dataDict[@"expireTime"] = @(4070880000);
                            dataDict[@"isForeverVip"] = @(YES);
                            dataDict[@"adEnabled"] = @(NO);
                            dataDict[@"adFree"] = @(YES);
                        }
                        
                        NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
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
    }
    
    return originalDataTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
}

+ (void)load {
    // 修复：将变量名class改为cls（class是Objective-C关键字）
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
