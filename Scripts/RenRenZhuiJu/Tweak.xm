#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

static IMP originalDataTaskWithRequestCompletionHandler;

id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    
    NSArray *targetAPIs = @[
        @"/api/v1/user/info",
        @"/api/v2/user/vip",
        @"/api/user/vipStatus",
        @"/api/vip/info",
        @"/api/app/config",
        @"/api/user/getInfo"
    ];
    
    for (NSString *api in targetAPIs) {
        if ([urlString containsString:api]) {
            void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (!error && data) {
                    NSError *jsonError;
                    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                    if (!jsonError && json) {
                        json[@"vip"] = @(YES);
                        json[@"isVip"] = @(YES);
                        json[@"vipType"] = @(3);
                        json[@"vipLevel"] = @(99);
                        json[@"expireTime"] = @(4070880000);
                        json[@"expireDate"] = @"2099-12-31";
                        json[@"isForeverVip"] = @(YES);
                        json[@"adEnabled"] = @(NO);
                        json[@"showAd"] = @(NO);
                        json[@"canWatchVip"] = @(YES);
                        json[@"canDownload"] = @(YES);
                        
                        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
                            NSMutableDictionary *dataDict = json[@"data"];
                            dataDict[@"vip"] = @(YES);
                            dataDict[@"isVip"] = @(YES);
                            dataDict[@"vipType"] = @(3);
                            dataDict[@"expireTime"] = @(4070880000);
                            dataDict[@"isForeverVip"] = @(YES);
                            dataDict[@"adEnabled"] = @(NO);
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
    Class class = objc_getClass("__NSURLSessionLocal");
    if (!class) class = [NSURLSession class];
    
    SEL selector = @selector(dataTaskWithRequest:completionHandler:);
    Method method = class_getInstanceMethod(class, selector);
    if (method) {
        originalDataTaskWithRequestCompletionHandler = method_getImplementation(method);
        method_setImplementation(method, (IMP)hookedDataTaskWithRequestCompletionHandler);
    }
}

@end
