#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface AFHTTPSessionManager : NSObject
@end

@interface NSURLSession (Hook)
@end

@implementation NSURLSession (Hook)

typedef id (*DataTaskCompletionHandlerIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static DataTaskCompletionHandlerIMP originalDataTaskWithRequestCompletionHandler;

// 完全复刻原作者的响应修改逻辑
static void modifyResponse(id responseObject) {
    // 处理字典类型响应（原作者核心逻辑）
    if ([responseObject isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *json = (NSMutableDictionary *)responseObject;
        
        // 处理嵌套data结构（所有接口都用这个结构）
        if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *dataDict = json[@"data"];
            
            // 解锁VIP播放权限（原作者核心修改）
            if (dataDict[@"is_vip"]) {
                dataDict[@"is_vip"] = @(0);
            }
            if (dataDict[@"vip_need"]) {
                dataDict[@"vip_need"] = @(0);
            }
            if (dataDict[@"play_auth"]) {
                dataDict[@"play_auth"] = @(1);
            }
            
            // 关闭广告
            if (dataDict[@"ad_status"]) {
                dataDict[@"ad_status"] = @(0);
            }
            if (dataDict[@"has_ad"]) {
                dataDict[@"has_ad"] = @(0);
            }
            
            // 解锁下载权限
            if (dataDict[@"can_download"]) {
                dataDict[@"can_download"] = @(1);
            }
            
            // 解锁最高清晰度
            if (dataDict[@"max_quality"]) {
                dataDict[@"max_quality"] = @(4);
            }
        }
        
        // 处理视频列表数组
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
    }
}

id hookedDataTaskWithRequestCompletionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlString = request.URL.absoluteString;
    
    // 精确匹配原作者的3个拦截路径
    NSArray *targetPaths = @[
        @"/api/v2/video/play",
        @"/api/v2/video/detail",
        @"/api/v2/user/info"
    ];
    
    // 精确匹配原作者的域名
    if ([urlString containsString:@"api.rrzj666.com"]) {
        for (NSString *path in targetPaths) {
            if ([urlString containsString:path]) {
                void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                    // 原作者只处理200状态码
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
        }
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
    }
    
    // Hook AFNetworking（人人追剧v1.1.1使用）
    Class afClass = objc_getClass("AFHTTPSessionManager");
    if (afClass) {
        SEL afSelector = @selector(dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:);
        Method afMethod = class_getInstanceMethod(afClass, afSelector);
        if (afMethod) {
            IMP originalAFIMP = method_getImplementation(afMethod);
            
            IMP hookedAFIMP = imp_implementationWithBlock(^id(AFHTTPSessionManager *self, SEL _cmd, NSURLRequest *request, id uploadProgress, id downloadProgress, void (^completionHandler)(NSURLResponse *, id, NSError *)) {
                NSString *urlString = request.URL.absoluteString;
                
                NSArray *targetPaths = @[
                    @"/api/v2/video/play",
                    @"/api/v2/video/detail",
                    @"/api/v2/user/info"
                ];
                
                if ([urlString containsString:@"api.rrzj666.com"]) {
                    for (NSString *path in targetPaths) {
                        if ([urlString containsString:path]) {
                            void (^modifiedHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                if (!error && httpResponse.statusCode == 200 && responseObject) {
                                    modifyResponse(responseObject);
                                }
                                completionHandler(response, responseObject, error);
                            };
                            
                            return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, modifiedHandler);
                        }
                    }
                }
                
                return ((id (*)(id, SEL, NSURLRequest *, id, id, void (^)(NSURLResponse *, id, NSError *)))originalAFIMP)(self, _cmd, request, uploadProgress, downloadProgress, completionHandler);
            });
            
            method_setImplementation(afMethod, hookedAFIMP);
        }
    }
}

@end
