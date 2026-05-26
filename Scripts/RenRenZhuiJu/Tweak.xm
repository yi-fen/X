#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface AFHTTPSessionManager : NSObject
@end

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

typedef id (*DataTaskCompletionHandlerIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
typedef id (*DataTaskWithURLIMP)(id, SEL, NSURL *, void (^)(NSData *, NSURLResponse *, NSError *));

static DataTaskCompletionHandlerIMP originalDataTaskWithRequestCompletionHandler;
static DataTaskWithURLIMP originalDataTaskWithURLCompletionHandler;

// 通用响应修改函数
static void modifyResponse(id responseObject) {
    if (!responseObject) return;
    
    // 处理字典类型响应
    if ([responseObject isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *json = (NSMutableDictionary *)responseObject;
        
        // 1. 全局VIP状态（用户信息接口）
        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *dataDict = json[@"data"];
            
            // 强制解锁所有VIP字段
            dataDict[@"is_vip"] = @(0);
            dataDict[@"vip_need"] = @(0);
            dataDict[@"play_auth"] = @(1);
            dataDict[@"vip_status"] = @(1);
            dataDict[@"is_forever_vip"] = @(1);
            dataDict[@"vip_expire_time"] = @(4070880000); // 2099-12-31
            
            // 关闭所有广告
            dataDict[@"ad_status"] = @(0);
            dataDict[@"has_ad"] = @(0);
            dataDict[@"show_splash_ad"] = @(0);
            dataDict[@"splash_ad_enable"] = @(0);
            
            // 解锁下载和清晰度
            dataDict[@"can_download"] = @(1);
            dataDict[@"max_quality"] = @(4);
        }
        
        // 2. 视频播放/详情接口
        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *dataArray = json[@"data"];
            for (NSInteger i=0; i<dataArray.count; i++) {
                if ([dataArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                    NSMutableDictionary *item = dataArray[i];
                    item[@"is_vip"] = @(0);
                    item[@"vip_need"] = @(0);
                    item[@"play_auth"] = @(1);
                    item[@"ad_status"] = @(0);
                    item[@"can_download"] = @(1);
                }
            }
        }
        
        // 3. 开屏广告接口（核心修复）
        if (json[@"ad_list"] || json[@"splash_ad"] || json[@"advertisement"]) {
            // 清空广告列表
            if (json[@"ad_list"]) json[@"ad_list"] = @[];
            if (json[@"splash_ad"]) json[@"splash_ad"] = @{};
            if (json[@"advertisement"]) json[@"advertisement"] = @{};
            
            // 强制关闭广告开关
            json[@"show_ad"] = @(0);
            json[@"ad_enable"] = @(0);
            json[@"splash_ad_show"] = @(0);
        }
    }
}

// Hook dataTaskWithRequest:completionHandler:
id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString.lowercaseString;
    
    // 拦截所有相关接口
    if ([urlString containsString:@"api.rrzj666.com"] || 
        [urlString containsString:@"ad.rrzj666.com"] ||
        [urlString containsString:@"splash.rrzj666.com"]) {
        
        void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (!error && httpResponse.statusCode == 200 && data) {
                NSError *jsonError;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                
                if (!jsonError) {
                    modifyResponse(jsonObject);
                    
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

// Hook dataTaskWithURL:completionHandler:（漏了这个导致部分广告请求没拦截）
id hookedDataTaskWithURLCompletionHandler(NSURLSession *self, SEL _cmd, NSURL *url, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = url.absoluteString.lowercaseString;
    
    if ([urlString containsString:@"api.rrzj666.com"] || 
        [urlString containsString:@"ad.rrzj666.com"] ||
        [urlString containsString:@"splash.rrzj666.com"]) {
        
        void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (!error && httpResponse.statusCode == 200 && data) {
                NSError *jsonError;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                
                if (!jsonError) {
                    modifyResponse(jsonObject);
                    
                    NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
                    if (modifiedData) {
                        completionHandler(modifiedData, response, error);
                        return;
                    }
                }
            }
            completionHandler(data, response, error);
        };
        
        return originalDataTaskWithURLCompletionHandler(self, _cmd, url, modifiedHandler);
    }
    
    return originalDataTaskWithURLCompletionHandler(self, _cmd, url, completionHandler);
}

+ (void)load {
    // Hook 系统 NSURLSession 两个核心方法
    Class cls = objc_getClass("__NSURLSessionLocal");
    if (!cls) cls = [NSURLSession class];
    
    SEL selector1 = @selector(dataTaskWithRequest:completionHandler:);
    Method method1 = class_getInstanceMethod(cls, selector1);
    if (method1) {
        originalDataTaskWithRequestCompletionHandler = (DataTaskCompletionHandlerIMP)method_getImplementation(method1);
        method_setImplementation(method1, (IMP)hookedDataTaskWithRequestCompletionHandler);
    }
    
    SEL selector2 = @selector(dataTaskWithURL:completionHandler:);
    Method method2 = class_getInstanceMethod(cls, selector2);
    if (method2) {
        originalDataTaskWithURLCompletionHandler = (DataTaskWithURLIMP)method_getImplementation(method2);
        method_setImplementation(method2, (IMP)hookedDataTaskWithURLCompletionHandler);
    }
    
    // Hook AFNetworking
    Class afClass = objc_getClass("AFHTTPSessionManager");
    if (afClass) {
        SEL afSelector = @selector(dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:);
        Method afMethod = class_getInstanceMethod(afClass, afSelector);
        if (afMethod) {
            IMP originalAFIMP = method_getImplementation(afMethod);
            
            IMP hookedAFIMP = imp_implementationWithBlock(^id(AFHTTPSessionManager *self, SEL _cmd, NSURLRequest *request, id uploadProgress, id downloadProgress, void (^completionHandler)(NSURLResponse *, id, NSError *)) {
                NSString *urlString = request.URL.absoluteString.lowercaseString;
                
                if ([urlString containsString:@"api.rrzj666.com"] || 
                    [urlString containsString:@"ad.rrzj666.com"] ||
                    [urlString containsString:@"splash.rrzj666.com"]) {
                    
                    void (^modifiedHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                        if (!error && httpResponse.statusCode == 200 && responseObject) {
                            modifyResponse(responseObject);
                        }
                        completionHandler(response, responseObject, error);
                    };
                    
                    return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, modifiedHandler);
                }
                
                return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, completionHandler);
            });
            
            method_setImplementation(afMethod, hookedAFIMP);
        }
    }
}

@end
